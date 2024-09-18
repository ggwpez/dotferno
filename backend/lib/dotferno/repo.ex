defmodule Dotferno.Repo do
  use Ecto.Repo,
    otp_app: :dotferno,
    adapter: Ecto.Adapters.Postgres
end
