#!/usr/local/bin/bash

set -eu

"$SCRIPT" command 'Elixir.Helix.Release' ecto_migrate
