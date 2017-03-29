use Mix.Config

config :helix_account,
  ecto_repos: [Helix.Account.Repo]

config :helix_account, Helix.Account.Repo,
  size: 4,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("HELIX_DB_USER") || "postgres",
  password: System.get_env("HELIX_DB_PASS") || "postgres",
  hostname: System.get_env("HELIX_DB_HOST") || "localhost",
  types: HELL.PostgrexTypes

config :guardian, Guardian,
  issuer: "helix",
  ttl: {1, :days},
  allowed_algos: ["HS512"],
  allowed_drift: 2_000,
  serializer: Helix.Account.Model.SessionSerializer

import_config "#{Mix.env}.exs"
