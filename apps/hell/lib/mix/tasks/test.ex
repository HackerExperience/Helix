defmodule Mix.Tasks.Helix.Test do

  use Mix.Task

  @content "Prunning database"
  @pad String.duplicate(" ", div(80 - String.length(@content), 2))
  @line_div IO.ANSI.yellow() <> "⚡" <> String.duplicate("=", 78) <> "⚡" <> IO.ANSI.default_color()
  @msg IO.ANSI.red() <> @pad <> @content <> @pad <> IO.ANSI.default_color()
  @command IO.ANSI.yellow() <> "mix test --no-prune" <> IO.ANSI.default_color()

  def run(argv \\ []) do
    {switches, _, _} = OptionParser.parse(argv, switches: [prune: :boolean])
    test_argv = argv -- ["--prune", "--no-prune"]

    if Keyword.get(switches, :prune, true) do
      Mix.Shell.IO.info @line_div
      Mix.Shell.IO.info @msg
      Mix.Shell.IO.info @line_div
      Mix.Shell.IO.info "If you don't want the database to be prunned, run #{@command}"

      Mix.Task.run("ecto.drop", [])
      Mix.Task.run("ecto.create", ["--quiet"])
      Mix.Task.run("ecto.migrate", ["--quiet"])

      Mix.Task.run("helix.seeds", [])
    end

    additional_opts = if "umbrella" in List.wrap(Keyword.get(switches, :exclude, [])) do
      []
    else
      ["--include", "umbrella"]
    end

    Mix.Task.run("test", additional_opts ++ test_argv)
  end
end