defmodule Helix.Mixfile do
  use Mix.Project

  def project do
    [
      app: :helix,
      version: "0.0.1",
      elixir: "~> 1.4",

      elixirc_options: elixirc_options(Mix.env),
      elixirc_paths: elixirc_paths(Mix.env),

      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      consolidate_protocols: Mix.env == :prod,

      aliases: aliases(),
      deps: deps(),

      dialyzer: [plt_add_apps: [:mix]],

      name: "Helix",
      source_url: "https://github.com/HackerExperience/Helix",
      homepage_url: "https://hackerexperience.com/",
      docs: docs()
    ]
  end

  def application do
    [
      mod: {Helix.Application, []},
      extra_applications: [:logger],
      included_applications: [:plug]
    ]
  end

  defp deps do
    [
      {:distillery, "~>1.2", runtime: :false},

      {:ecto, "~> 2.1", override: true},
      {:postgrex, github: "elixir-ecto/postgrex", ref: "87178f1", override: true},

      {:helf, github: "HackerExperience/HELF"},
      {:poison, "~> 2.0"},

      {:comeonin, "~> 2.5"},
      {:guardian, "~> 0.14"},
      {:timex, "~> 3.0"},

      {:burette, git: "https://github.com/HackerExperience/burette", only: :test},

      {:ex_machina, "~> 1.0", only: :test},
      {:earmark, "~> 1.1", only: :dev},
      {:ex_doc, "~> 0.15", only: :dev},

      {:credo, "~> 0.7", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "helix.seeds"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["compile", "helix.test"]
    ]
  end

  defp docs do
    [
      logo: "help/logo.png",
      extras: []
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

  defp elixirc_paths(:test),
    do: ["lib", "test/support"]
  defp elixirc_paths(_),
    do: ["lib"]
end
