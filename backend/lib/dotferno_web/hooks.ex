defmodule DotfernoWeb.Hooks do

  def on_mount(:default, _params, _session, socket) do
    {:cont, socket}
  end
end
