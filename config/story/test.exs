# Story shares the same database with Entity, but we use a separate Repo module
# for separation/abstraction purposes.

use Mix.Config

prefix = System.get_env("HELIX_DB_PREFIX") || "helix"

config :helix, Helix.Story.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: prefix <> "_test_entity"
