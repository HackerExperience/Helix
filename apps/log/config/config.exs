use Mix.Config

use Mix.Config

config :log,
  ecto_repos: []

import_config "#{Mix.env}.exs"