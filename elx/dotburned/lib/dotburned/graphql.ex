defmodule Dotburned.Schema.Burn do
  defstruct [:id, :blockNumber, :timestamp, :amount, :aggregated]

  def from_map(%{"id" => id, "blockNumber" => blockNumber, "timestamp" => timestamp, "amount" => amount, "aggregated" => aggregated}) do
    {:ok, timestamp, _} = DateTime.from_iso8601(timestamp)
    %__MODULE__{
      id: id,
      blockNumber: blockNumber,
      timestamp: timestamp,
      amount: Integer.parse(amount) |> elem(0),
      aggregated: Integer.parse(aggregated) |> elem(0)
    }
  end
end

defmodule Dotburned.GraphQl do
  use GenServer
  alias Phoenix.PubSub
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{url: "https://3e8b1a97-78b3-4bb6-8144-63621330abbd.squids.live/dotburned/v/v1/graphql"}, opts)
  end

  @impl true
  def init(%{ :url => url }) do
    IO.puts "Connecting to GraphQL server..."
    client = Req.new(base_url: url) |> AbsintheClient.attach()

    send(self(), "fetch_new")
    :timer.send_after(10_000, self(), "fetch_old")
    :timer.send_interval(60_000, self(), "fetch_new")

    {:ok, %{ :client => client, :newest_id => "", :oldest_id => ""}}
  end

  @impl true
  def handle_info("fetch_new", %{ :client => client, :newest_id => id }=state) do
    Logger.info("Fetching burns since id #{id}...")
    case fetch_burns(client, {:since, id}) do
      {:ok, []} -> {:noreply, state}
      {:ok, burns} ->
        burns = for burn <- burns do
          burn = Dotburned.Schema.Burn.from_map(burn)
          PubSub.broadcast(Dotburned.PubSub, "new_burn", burn)
          burn.id
        end
        first = Enum.at(burns, 0)
        state = Map.put(state, :newest_id, first)
        oldest = Enum.at(burns, -1)
        state = Map.put(state, :oldest_id, oldest)

        {:noreply, state}
      {:error, errors} -> Logger.error("Error fetching burns: #{inspect(errors)}")
    end
  end

  @impl true
  def handle_info("fetch_old", %{ :client => client, :oldest_id => id }=state) do
    Logger.info("Fetching old until id #{id}...")
    case fetch_burns(client, {:until, id}) do
      {:ok, []} -> {:noreply, state}
      {:ok, burns} ->
        last = for burn <- burns do
          burn = Dotburned.Schema.Burn.from_map(burn)
          PubSub.broadcast(Dotburned.PubSub, "new_burn", burn)
          burn
        end |> List.last()

        backfill_cutoff = DateTime.utc_now() |> DateTime.add(-8, :day)
        if last.timestamp < backfill_cutoff do
          Logger.info("Backfill complete. Listening for new burns.")
        else
          Logger.info("Queueing another backfill fetch")
          :timer.send_after(10_000, self(), "fetch_old")
        end

        {:noreply, Map.put(state, :oldest_id, last.id)}
      {:error, errors} -> Logger.error("Error fetching burns: #{inspect(errors)}")
    end
  end

  defp fetch_burns(client, {:since, id}) do
    query(client, 'id_gt: "#{id}"')
  end

  defp fetch_burns(client, {:until, id}) do
    query(client, 'id_lt: "#{id}"')
  end

  defp query(client, pred) do
    query = """
      query {
        burns(limit: 10, orderBy: id_DESC, where: {#{pred}}) {
          id
          amount
          aggregated
          blockNumber
          timestamp
        }
      }
    """
    case Req.post(client, graphql: query) do
      {:error, %{"errors" => errors}} ->
          {:error, errors}
      {:ok, %{body: %{"data" => %{"burns" => burns}}}} ->
        Logger.info("Fetched #{length(burns)} burns")
        if burns == [] do
          {:ok, []}
        else
          {:ok, burns}
        end
    end
  end
end
