defmodule Mix.Tasks.Helix.Seeds do
  use Mix.Task

  def run(_) do
    "apps/*/priv/repo/seeds.exs"
    |> Path.wildcard()
    |> Enum.each(&Mix.Task.rerun("run", [&1]))
  end
end