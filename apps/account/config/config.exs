use Mix.Config

config :account,
  ecto_repos: [HELM.Account.Repo]

config :account, HELM.Account.Repo,
  size: 4,
  adapter: Ecto.Adapters.Postgres,
  database: "account_service",
  username: System.get_env("HELIX_DB_USER") || "postgres",
  password: System.get_env("HELIX_DB_PASS") || "postgres",
  hostname: System.get_env("HELIX_DB_HOST") || "localhost",
  extensions: [
    {Postgrex.Extensions.Network, nil}
  ]

import_config "#{Mix.env}.exs"