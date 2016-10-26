use Mix.Config

config :npc,
  ecto_repos: [HELM.NPC.Model.Repo]
config :npc, HELM.NPC.Model.Repo,
  size: 4,
  adapter: Ecto.Adapters.Postgres,
  database: "npc_service",
  username: System.get_env("HELIX_DB_USER") || "postgres",
  password: System.get_env("HELIX_DB_PASS") || "postgres",
  hostname: System.get_env("HELIX_DB_HOST") || "localhost"

import_config "#{Mix.env}.exs"