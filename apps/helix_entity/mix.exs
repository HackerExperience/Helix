defmodule Helix.Entity.Mixfile do
  use Mix.Project

  def project do
    [
      app: :helix_entity,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      consolidate_protocols: Mix.env == :prod,
      elixirc_options: elixirc_options(Mix.env),
      elixirc_paths: compile_paths(Mix.env),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Helix.Entity.App, []}
    ]
  end

  defp elixirc_options(:dev) do
    # On dev, by default, allow to compile even with warnings, unless explicitly
    # required not to
    warnings_as_errors? = System.get_env("HELIX_SKIP_WARNINGS") == "false"

    [warnings_as_errors: warnings_as_errors?]
  end
  defp elixirc_options(_) do
    # On test and prod, don't compile unless no warning is issued
    warnings_as_errors? = System.get_env("HELIX_SKIP_WARNINGS") != "true"

    [warnings_as_errors: warnings_as_errors?]
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