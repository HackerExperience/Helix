use Mix.Config

config :account,
  ecto_repos: [HELM.Account.Model.Repo]

config :account, HELM.Account.Model.Repo,
  size: 4,
  adapter: Ecto.Adapters.Postgres,
  database: "account_service",
  username: System.get_env("HELIX_DB_USER") || "postgres",
  password: System.get_env("HELIX_DB_PASS") || "postgres",
  hostname: System.get_env("HELIX_DB_HOST") || "localhost"

import_config "#{Mix.env}.exs"