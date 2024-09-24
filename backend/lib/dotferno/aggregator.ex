defmodule Dotferno.Aggregator do
  use GenServer
  alias Phoenix.PubSub
  require Logger

  def buckets_today() do
    GenServer.call(__MODULE__, :buckets_today)
  end

  def buckets_year() do
    GenServer.call(__MODULE__, :buckets_year)
  end

  def biggest_today() do
    GenServer.call(__MODULE__, :biggest_today)
  end

  def biggest_week() do
    GenServer.call(__MODULE__, :biggest_week)
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: __MODULE__])
  end

  @impl true
  def init(:ok) do
    PubSub.subscribe(Dotferno.PubSub, "new_burn")
    :timer.send_interval(1000, self(), :update)

    state = %{
      all_burns: [],
      needs_update: false,
      last_updated: DateTime.from_unix!(0),
      buckets_today: [],
      buckets_year: [],
      biggest_today: 0,
      biggest_week: 0
    }

    {:ok, recompute(state)}
  end

  @impl true
  def handle_call(:buckets_today, _from, state) do
    {:reply, state.buckets_today, state}
  end

  @impl true
  def handle_call(:buckets_year, _from, state) do
    {:reply, state.buckets_year, state}
  end

  @impl true
  def handle_call(:biggest_today, _from, state) do
    {:reply, state.biggest_today, state}
  end

  @impl true
  def handle_call(:biggest_week, _from, state) do
    {:reply, state.biggest_week, state}
  end

  @impl true
  def handle_info(:update, state) do
    {:noreply, recompute(state)}
  end

  @impl true
  def handle_info(burn, state) do
    all_burns = [burn | state.all_burns]

    Logger.debug("Ingesting burn into the aggregator. Total burns: #{length(all_burns)}")

    {:noreply, %{state | all_burns: all_burns, needs_update: true}}
  end

  @resolution_today 3600

  defp recompute(state) do
    now = DateTime.utc_now()
    historic_cutoff = now |> DateTime.add(-8, :day)
    since = now |> DateTime.diff(state.last_updated, :second)

    all_burns =
      state.all_burns
      |> Enum.sort_by(& &1.id)
      |> Enum.drop_while(fn burn -> DateTime.compare(burn.timestamp, historic_cutoff) == :lt end)
      |> Enum.reverse()

    check_ordered(all_burns)

    if length(all_burns) != length(state.all_burns) do
      Logger.info("Pruned #{length(state.all_burns) - length(all_burns)} historic burns")
    end

    state = Map.put(state, :all_burns, all_burns)

    # Recompute at least every 60 secs, but not more often than every second - if needed.
    if (state.needs_update and since >= 1) or since > 5 do
      task = Task.async(fn -> compute_biggest(now, all_burns) end)
      Logger.info("Recomputing burn aggregates")

      state =
        Map.put(
          state,
          :buckets_today,
          aggregate!(
            state.all_burns,
            DateTime.utc_now(),
            @resolution_today,
            div(24 * 3600, @resolution_today)
          )
        )

      state =
        Map.put(
          state,
          :buckets_year,
          aggregate!(state.all_burns, DateTime.utc_now(), 3600 * 24, 7)
        )

      state = Map.put(state, :needs_update, false)
      state = Map.put(state, :last_updated, now)

      PubSub.broadcast(Dotferno.PubSub, "buckets", %{
        buckets_today: state.buckets_today
      })

      PubSub.broadcast(Dotferno.PubSub, "buckets", %{
        buckets_year: state.buckets_year
      })

      {biggest_today, biggest_week} = Task.await(task)
      state = Map.put(state, :biggest_today, biggest_today)
      state = Map.put(state, :biggest_week, biggest_week)

      PubSub.broadcast(Dotferno.PubSub, "biggest", %{
        biggest_today: biggest_today,
        biggest_week: biggest_week
      })

      state
    else
      Logger.debug("No need to recompute burn aggregates since #{since} seconds.")
      state
    end
  end

  def compute_biggest(now, all_burns) do
    # Compute biggest today
    biggest_today =
      all_burns
      |> Enum.take_while(fn burn ->
        DateTime.compare(burn.timestamp, DateTime.add(now, -24 * 3600, :second)) == :gt
      end)
      |> Enum.sort_by(& &1.amount)
      |> Enum.reverse()
      |> Enum.take(5)

    # Compute biggest this week
    biggest_week =
      all_burns
      |> Enum.take_while(fn burn ->
        DateTime.compare(burn.timestamp, DateTime.add(now, -7 * 24 * 3600, :second)) == :gt
      end)
      |> Enum.sort_by(& &1.amount)
      |> Enum.reverse()
      |> Enum.take(5)

    Logger.debug("Biggest today: #{inspect(biggest_today)}")

    {biggest_today, biggest_week}
  end

  def aggregate!(all_burns, now, slice_s, count) do
    case aggregate(all_burns, now, slice_s, count) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @doc """
  Aggregate a list of burns into at most `count` summaries of `slice_s` seconds duration.
  """
  def aggregate(_all_burns, _now, slice_s, count) when slice_s <= 0 or count <= 0 do
    {:error, "slice_s and count must be positive"}
  end

  def aggregate(all_burns, now, slice_s, count) do
    check_ordered(all_burns)
    buckets = Enum.map(0..(count - 1), fn _ -> 0 end)
    time_buckets = Enum.map(1..count, fn i -> DateTime.add(now, -i * slice_s, :second) end)
    buckets = aggregate_h(all_burns, slice_s, 0, buckets, time_buckets)

    {:ok, {buckets, time_buckets}}
  end

  defp aggregate_h([], _slice_s, _bucket_index, buckets, _time_buckets) do
    buckets
  end

  defp aggregate_h([burn | tail_burns], slice_s, bucket_index, buckets, time_buckets) do
    cond do
      bucket_index >= length(buckets) ->
        buckets

      DateTime.to_unix(burn.timestamp) > DateTime.to_unix(Enum.at(time_buckets, bucket_index)) ->
        buckets = List.update_at(buckets, bucket_index, &(&1 + burn.amount))
        aggregate_h(tail_burns, slice_s, bucket_index, buckets, time_buckets)

      true ->
        aggregate_h([burn | tail_burns], slice_s, bucket_index + 1, buckets, time_buckets)
    end
  end

  def update_today(_burn, _hrs_ago, state) do
    state
  end

  def aggregate([]) do
    {:error, "Cannot aggregate empty list"}
  end

  def check_ordered(burns) do
    if burns != burns |> Enum.sort_by(& &1.id) |> Enum.reverse() do
      raise ArgumentError, "Burns must be ordered by timestamp"
    end
  end
end
