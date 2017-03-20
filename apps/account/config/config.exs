use Mix.Config

config :account,
  ecto_repos: [Helix.Account.Repo]

config :account, Helix.Account.Repo,
  size: 4,
  adapter: Ecto.Adapters.Postgres,
  database: "account_service"

config :guardian, Guardian,
  issuer: "account",
  ttl: {1, :days},
  allowed_algos: ["HS512"],
  secret_key: System.get_env("HELIX_JWK_KEY"),
  serializer: Helix.Account.Model.Session

import_config "#{Mix.env}.exs"
