#!/usr/bin/env bash

set -eu

# Go to Helix root
cd $(dirname $(realpath $0))
cd ../../

HELIX_ROOT=$PWD
MIX_FILE=$HELIX_ROOT/mix.exs
IEX_FILE=$HELIX_ROOT/.iex.exs

# Replace elixirc option; ensures `test/support` gets compiled on :dev
ed -s $HELIX_ROOT/mix.exs <<< $',s/(:test)/(_)/g\nw'

# Create temporary IEx file with instructions
echo "IO.puts \"\n\nType 'use Helix.Maroto' for maximum marotagem!!11!\n\n\"" > $IEX_FILE

# Force synchronous behaviour on HELF and run Helix interactively
HELF_FORCE_SYNC=1 iex -S mix

# Clean up any changes
git checkout $MIX_FILE
rm $IEX_FILE
