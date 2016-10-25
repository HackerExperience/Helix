use Mix.Config

config :npc,
  ecto_repos: [HELM.NPC.Repo]
config :npc, HELM.NPC.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "npc_service",
  username: System.get_env("HELIX_DB_USER"),
  password: System.get_env("HELIX_DB_PASS"),
  hostname: System.get_env("HELIX_DB_HOST")