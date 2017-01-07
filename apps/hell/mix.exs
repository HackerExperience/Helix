defmodule HELL.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hell,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      elixirc_options: elixirc_options(Mix.env),
      elixirc_paths: compile_paths(Mix.env),
      deps: deps()]
  end

  def application do
    []
  end

  defp elixirc_options(:dev),
    do: []
  defp elixirc_options(_),
    do: [warnings_as_errors: true]

  defp compile_paths(:test),
    do: ["lib", "test/helper"]
  defp compile_paths(_),
    do: ["lib"]

  defp deps do
    []
  end
end