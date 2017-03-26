#!/usr/local/bin/bash

set -eu

"$SCRIPT" command 'Elixir.Helix.Account.Release' ecto_create
"$SCRIPT" command 'Elixir.Helix.Entity.Release' ecto_create
"$SCRIPT" command 'Elixir.Helix.Hardware.Release' ecto_create
"$SCRIPT" command 'Elixir.Helix.Log.Release' ecto_create
"$SCRIPT" command 'Elixir.Helix.NPC.Release' ecto_create
"$SCRIPT" command 'Elixir.Helix.Process.Release' ecto_create
"$SCRIPT" command 'Elixir.Helix.Server.Release' ecto_create
"$SCRIPT" command 'Elixir.Helix.Software.Release' ecto_create
