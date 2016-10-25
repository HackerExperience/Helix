use Mix.Config

config :hardware,
  ecto_repos: [HELM.Hardware.Repo]
config :hardware, HELM.Hardware.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "hardware_service",
  username: System.get_env("HELIX_DB_USER"),
  password: System.get_env("HELIX_DB_PASS"),
  hostname: System.get_env("HELIX_DB_HOST")