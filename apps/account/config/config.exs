use Mix.Config

config :account, ecto_repos: [HELM.Account.Repo]
config :account, HELM.Account.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "account_service",
  username: System.get_env("HELIX_DB_USER"),
  password: System.get_env("HELIX_DB_PASS"),
  hostname: System.get_env("HELIX_DB_HOST")
