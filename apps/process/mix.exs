defmodule Helix.Process.Mixfile do
  use Mix.Project

  def project do
    [
      app: :process,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      elixirc_options: elixirc_options(Mix.env),
      elixirc_paths: compile_paths(Mix.env),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Helix.Process.App, []}
    ]
  end

  defp elixirc_options(:dev),
    do: []
  defp elixirc_options(_),
    do: [warnings_as_errors: true]

  defp compile_paths(:test),
    do: ["lib", "test/test_helper"]
  defp compile_paths(_),
    do: ["lib"]

  defp deps do
    [
      {:helix_core, in_umbrella: true},
      {:timex, "~> 3.0"}
    ]
  end
end