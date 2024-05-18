defmodule Dotburned.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DotburnedWeb.Telemetry,
      # Dotburned.Repo,
      {DNSCluster, query: Application.get_env(:dotburned, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Dotburned.PubSub},
      # Start the Finch HTTP client for sending emails
      # {Finch, name: Dotburned.Finch},
      # Start a worker by calling: Dotburned.Worker.start_link(arg)
      # {Dotburned.Worker, arg},
      # Start to serve requests, typically the last entry
      DotburnedWeb.Endpoint,
      Dotburned.Aggregator,
      Dotburned.GraphQl,
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dotburned.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DotburnedWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
