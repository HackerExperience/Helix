use Mix.Config

import_config "../../helf_router/config/config.exs"

config :software, ecto_repos: [HELM.Software.Repo]
config :software, HELM.Software.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "software_service",
  username: System.get_env("HELIX_DB_USER"),
  password: System.get_env("HELIX_DB_PASS"),
  hostname: System.get_env("HELIX_DB_HOST")
