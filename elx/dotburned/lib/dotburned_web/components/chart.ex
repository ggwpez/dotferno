defmodule DotfernoWeb.Components.Charts do
  @moduledoc """
  Holds the charts components
  """
  use Phoenix.Component
  require Logger

  attr :id, :string, required: true
  attr :type, :string, default: "line"
  attr :width, :integer, default: nil
  attr :height, :integer, default: nil
  attr :toolbar, :boolean, default: false
  attr :dataset, :list, default: []
  attr :categories, :list, default: []

  def line_chart(assigns) do
    # This component has DOM-patching disabled, since it gets its data fed over WS.
    ~H"""
    <div
      id={@id}
      class="[&>div]:mx-auto"
      phx-hook="Chart"
      phx-update="ignore"
      data-config={Jason.encode!(trim %{
        height: @height,
        width: @width,
        type: @type,
        animations: %{
          enabled: true
        },
        toolbar: %{
          show: @toolbar
        }
      })}
      data-series={Jason.encode!(@dataset)}
      data-categories={Jason.encode!(@categories)}
    ></div>
    """
  end

  defp trim(map) do
    Map.reject(map, fn {_key, val} -> is_nil(val) || val == "" end)
  end
end

defmodule DotfernoWeb.Components.ChartComponent do
  use Phoenix.LiveComponent
  import DotfernoWeb.Components.Charts
  require Logger

  def render(assigns) do
    ~H"""
    <div class="bg-white border border-gray-200 rounded-lg glow">
      <.line_chart
        id={"#{@id}-chart"}
        dataset={[
          %{
            name: "burns",
            data: @y,
            type: @type
          }
        ]}
        categories={@x}
      />
    </div>
    """
  end

  def update(%{event: "update_chart", y: y, x: x}, socket) do
    id = socket.assigns.id
    Logger.info("Updating chart with id: #{id}-chart")

    # zip the data
    data = Enum.zip(x, y) |> Enum.map(fn {x, y} -> %{x: x, y: y} end)

    dataset = [
      %{
        name: "burns",
        data: data,
        type: "bar"
      }
    ]
    {
      :ok,
      socket
      |> push_event("update-dataset-#{id}-chart", %{dataset: dataset})
    }
  end

  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
    }
  end
end
