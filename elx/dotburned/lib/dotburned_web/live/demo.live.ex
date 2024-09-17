defmodule DotburnedWeb.DemoLive do
  use Phoenix.LiveView, layout: {DotburnedWeb.Layouts, :app}
  import DotburnedWeb.CoreComponents
  import Dotburned.Format
  alias Dotburned.Aggregator
  alias Phoenix.PubSub
  import Dotburned.Format
  import Logger

  @impl true
  def mount(_params, _session, socket) do
    buckets_today = Aggregator.buckets_today()
    buckets_year = Aggregator.buckets_year()

    socket = update_state(%{buckets_today: buckets_today}, socket)
    socket = update_state(%{buckets_year: buckets_year}, socket)
    socket = assign(socket, biggest_today: Aggregator.biggest_today(), biggest_week: Aggregator.biggest_week())

    PubSub.subscribe(Dotburned.PubSub, "buckets")
    PubSub.subscribe(Dotburned.PubSub, "biggest")

    {:ok, socket}
  end

  @impl true
  def handle_info(%{buckets_today: _}=e, socket) do
    socket = update_state(e, socket)
    send_update(DotburnedWeb.Components.ChartComponent, id: :chart_today, event: "update_chart", y: socket.assigns.buckets_today, x: socket.assigns.timings_today)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{buckets_year: _}=e, socket) do
    socket = update_state(e, socket)
    send_update(DotburnedWeb.Components.ChartComponent, id: :chart_year, event: "update_chart", y: socket.assigns.buckets_year, x: socket.assigns.timings_year)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{biggest_today: _, biggest_week: _}=e, socket) do
    {:noreply, assign(socket, e)}
  end

  @impl true
  def handle_info(%{event: "new_burn", burn: burn}, socket) do
    buckets_today = Aggregator.buckets_today()
    buckets_year = Aggregator.buckets_year()

    socket = update_state(%{buckets_today: buckets_today}, socket)
    socket = update_state(%{buckets_year: buckets_year}, socket)

    send_update(DotburnedWeb.Components.ChartComponent, id: :chart_today, event: "update_chart", y: socket.assigns.buckets_today, x: socket.assigns.timings_today)
    send_update(DotburnedWeb.Components.ChartComponent, id: :chart_year, event: "update_chart", y: socket.assigns.buckets_year, x: socket.assigns.timings_year)

    {:noreply, socket}
  end

  def update_state(%{buckets_today: {buckets_today, timings}}, socket) do
    buckets_today = buckets_today |> Enum.map(fn x -> Dotburned.Format.plank_to_dot x end)
    x_today = Enum.map(1..length(buckets_today), &(&1))
    sum_today = Enum.sum(buckets_today) |> Kernel.round()

    assign(socket, buckets_today: buckets_today, sum_today: sum_today, timings_today: render_timings(timings))
  end

  def update_state(%{buckets_year: {buckets_year, timings}}, socket) do
    buckets_year = buckets_year |> Enum.map(fn x -> Dotburned.Format.plank_to_dot x end)
    x_year = Enum.map(1..length(buckets_year), &(&1))
    sum_year = Enum.sum(buckets_year) |> Kernel.round()

    assign(socket, buckets_year: buckets_year, sum_year: sum_year, timings_year: render_dates(timings))
  end

  def render_timings(timings) do
    Enum.map(timings, fn t -> t |> DateTime.truncate(:second) |> DateTime.to_iso8601() end)
  end

  def render_dates(timings) do
    Enum.map(timings, fn t -> t |> DateTime.to_date() |> Date.to_iso8601() end)
  end

  @impl true
  def render(assigns) do
    buckets_today = assigns.buckets_today
    buckets_year = assigns.buckets_year
    timings_today = assigns.timings_today
    timings_year = assigns.timings_year

    ~H"""
    <div class="flex flex-wrap">

    <div class="flex justify-between w-full">
      <div class="flex justify-end">
        <div class="p-4">
            <div class="flex rounded-lg items-center flex-col border glow pt-6 pb-6 pl-8 pr-8">
              <div class="text-xs">
                24 hrs
              </div>
              <div class="text-lg font-medium text-[#E6007A]">
                <%= fmt_dot @sum_today %>
              </div>
            </div>
        </div>

        <div class="p-4">
            <div class="flex rounded-lg items-center flex-col border glow pt-6 pb-6 pl-8 pr-8">
              <div class="text-xs">
                7 days
              </div>
              <div class="text-lg font-medium text-[#E6007A]">
                <%= fmt_dot @sum_year %>
              </div>
            </div>
        </div>
      </div>
    </div>


    <!-- card 1 -->
    <div class="p-4 w-full">
        <div class="flex rounded-lg h-full flex-col">
            <div class="flex items-center mb-3">
                <h2 class="text-lg font-medium">
                  Burns per hour (24 hrs)
                </h2>
            </div>
            <div>
              <.live_component module={DotburnedWeb.Components.ChartComponent} id={:chart_today} y={buckets_today} x={timings_today} type="bar" />
            </div>
        </div>
    </div>

    <div class="flex justify-begin">
        <div class="p-4">
          <div class="flex items-center mb-3">
                <h2 class="text-lg font-medium">
                  Top today
                </h2>
            </div>
            <div class="flex rounded-lg items-center flex-col border glow">
              <ul class="max-w-md divide-y">
                <%= for v <- Enum.take(@biggest_today, 3) do %>
                  <li class="p-3">
                    <div class="flex items-center space-x-4 rtl:space-x-reverse">
                      <div class="flex-1 items-center text-sm font-semibold">
                        <%= fmt_plank v.amount %>
                      </div>
                      <div class="inline-flex min-w-0">
                        <p class="text-sm font-medium truncate">
                          <.link href={link_block v.blockNumber} target="_blank">
                            <%= fmt_time_ago v.timestamp %>
                          </.link>
                        </p>
                      </div>
                    </div>
                  </li>
                <% end %>
              </ul>
            </div>
        </div>
        <div class="p-4">
            <div class="flex items-center mb-3">
                <h2 class="text-lg font-medium">
                  Top this week
                </h2>
            </div>
            <div class="flex rounded-lg items-center flex-col border glow">
              <ul class="max-w-md divide-y">
                <%= for v <- Enum.take(@biggest_week, 3) do %>
                  <li class="p-3">
                    <div class="flex items-center space-x-4 rtl:space-x-reverse">
                      <div class="flex-1 items-center text-sm font-semibold">
                        <%= fmt_plank v.amount %>
                      </div>
                      <div class="inline-flex min-w-0">
                        <p class="text-sm font-medium truncate">
                          <.link href={link_block v.blockNumber} target="_blank">
                            <%= fmt_time_ago v.timestamp %>
                          </.link>
                        </p>
                      </div>
                    </div>
                  </li>
                <% end %>
              </ul>
            </div>
        </div>
      </div>

    <div class="p-4 w-full">
      <div class="flex rounded-lg h-full flex-col">
          <div class="flex items-center mb-3">
              <h2 class="text-lg font-medium">
                Burns per day (7 days)
              </h2>
          </div>
          <div>
            <.live_component module={DotburnedWeb.Components.ChartComponent} id={:chart_year} y={buckets_year} x={timings_year} type="bar" />
          </div>
      </div>
    </div>
    </div>
    """
  end
end
