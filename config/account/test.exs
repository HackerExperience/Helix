use Mix.Config

prefix = System.get_env("HELIX_DB_PREFIX") || "helix"

config :bcrypt_elixir, :log_rounds, 2

config :helix, Helix.Account.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: prefix <> "_test_account",
  ownership_timeout: 90_000
