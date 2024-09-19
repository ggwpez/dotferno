defmodule DotfernoWeb.Hooks do
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    {:cont, socket}
  end

end
