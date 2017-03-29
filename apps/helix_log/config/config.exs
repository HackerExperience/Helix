use Mix.Config

use Mix.Config

config :helix_log,
  ecto_repos: [Helix.Log.Repo]
config :helix_log, Helix.Log.Repo,
  size: 4,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("HELIX_DB_USER") || "postgres",
  password: System.get_env("HELIX_DB_PASS") || "postgres",
  hostname: System.get_env("HELIX_DB_HOST") || "localhost",
  types: HELL.PostgrexTypes

import_config "#{Mix.env}.exs"
