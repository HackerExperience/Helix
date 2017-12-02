use Mix.Config

config :helix, Helix.Server.Repo,
  priv: "priv/repo/server",
  pool_size: 3,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("HELIX_DB_USER") || "postgres",
  password: System.get_env("HELIX_DB_PASS") || "postgres",
  hostname: System.get_env("HELIX_DB_HOST") || "localhost",
  types: HELL.PostgrexTypes,
  timeout: 900_000
