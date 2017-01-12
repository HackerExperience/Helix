use Mix.Config

use Mix.Config

config :log,
  ecto_repos: [Helix.Log.Repo]
config :log, Helix.Log.Repo,
  size: 4,
  adapter: Ecto.Adapters.Postgres,
  database: "log",
  username: System.get_env("HELIX_DB_USER") || "postgres",
  password: System.get_env("HELIX_DB_PASS") || "postgres",
  hostname: System.get_env("HELIX_DB_HOST") || "localhost"

import_config "#{Mix.env}.exs"