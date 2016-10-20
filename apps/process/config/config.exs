use Mix.Config

config :process, ecto_repos: [HELM.Process.Repo]
config :process, HELM.Process.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "process_service",
  username: System.get_env("HELIX_DB_USER"),
  password: System.get_env("HELIX_DB_PASS"),
  hostname: System.get_env("HELIX_DB_HOST")

config :remix,
  escript: true,
  silent: true
