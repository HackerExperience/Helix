defmodule Helix.Software.Mixfile do
  use Mix.Project

  def project do
    [
      app: :software,
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
      mod: {Helix.Software.App, []}
    ]
  end

  defp elixirc_options(:dev),
    do: []
  defp elixirc_options(_) do
    skip? = System.get_env("HELIX_SKIP_WARNINGS") == "true"
    warnings? = !skip?

    [warnings_as_errors: warnings?]
  end

  defp compile_paths(:test),
    do: ["lib", "test/support"]
  defp compile_paths(_),
    do: ["lib"]

  defp deps do
    [
      {:helix_core, in_umbrella: true},
      {:ex_machina, "~> 1.0", only: :test}
    ]
  end
end
