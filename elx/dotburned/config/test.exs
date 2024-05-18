import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :dotburned, DotburnedWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "eVG+t3FGj/Z42NCi13Ycvc3jjA+WpgWgF+sDyE261B71pK6407IpONcqtqHDwTYA",
  server: false

# In test we don't send emails.
config :dotburned, Dotburned.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true
