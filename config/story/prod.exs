# Story shares the same database with Entity, but we use a separate Repo module
# for separation/abstraction purposes.

use Mix.Config

prefix = "${HELIX_DB_PREFIX}"

config :helix, Helix.Story.Repo,
  pool_size: "${HELIX_DB_POOL_SIZE}",
  username: "${HELIX_DB_USER}",
  password: "${HELIX_DB_PASS}",
  hostname: "${HELIX_DB_HOST}",
  database: prefix <> "_prod_entity"
