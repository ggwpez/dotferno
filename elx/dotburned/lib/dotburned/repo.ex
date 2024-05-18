defmodule Dotburned.Repo do
  use Ecto.Repo,
    otp_app: :dotburned,
    adapter: Ecto.Adapters.Postgres
end
