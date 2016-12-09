use Mix.Config

config :comeonin, :bcrypt_log_rounds, 2

config :account, HELM.Account.Repo,
  pool: Ecto.Adapters.SQL.Sandbox