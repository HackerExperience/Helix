defmodule Helix.Mixfile do
  use Mix.Project

  def project do
    [
      app: :helix,
      version: "0.0.1",
      elixir: "~> 1.5",

      elixirc_options: elixirc_options(Mix.env),
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: Mix.compilers,

      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      consolidate_protocols: Mix.env == :prod,

      aliases: aliases(),
      deps: deps(),

      dialyzer: [plt_add_apps: [:mix, :phoenix_pubsub]],
      test_coverage: [tool: ExCoveralls, test_task: "test.cover"],

      preferred_cli_env: %{
        "test.quick": :test,
        "test.full": :test,
        "test.unit": :test,
        "test.cluster": :test,
        "test.external": :test,
        "test.cover": :test,
        "pr": :test,
        "coveralls": :test,
        "coveralls.html": :test,
        "coveralls.travis": :test
      },

      name: "Helix",
      source_url: "https://github.com/HackerExperience/Helix",
      homepage_url: "https://hackerexperience.com/",
      docs: docs()
    ]
  end

  def application do
    [
      mod: {Helix.Application, []},
      extra_applications: [:logger, :crypto]
    ]
  end

  defp deps do
    [
      {:distillery, "~>1.2", runtime: false},

      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:cowboy, "~> 1.0"},
      {:corsica, "~> 0.5"},

      # Review: required for 1.5, why?
      {:hackney, "~>1.8"},
      {:poolboy, "~>1.5"},

      {:ecto, "~> 2.1"},
      {:postgrex, "~> 0.13.3"},

      {:helf, "~> 0.0.2"},
      {:poison, "~> 3.0"},

      {:comeonin, "~> 4.0.3"},
      {:bcrypt_elixir, "~> 1.0"},

      {:timex, "~> 3.1"},

      {:burette, git: "https://github.com/HackerExperience/burette"},

      {:ex_machina, "~> 1.0", only: :test},
      {:earmark, "~> 1.1", only: :dev},
      {:ex_doc, "~> 0.15", only: :dev},

      {:inch_ex, "~> 0.5.6", only: [:dev, :test]},

      {:credo, "~> 0.8", only: [:dev, :test]},
      {:excoveralls, "~> 0.7.2", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "helix.seeds"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test.full": [
        "helix.test --exclude sequential --exclude cluster --exclude external",
        "helix.test --no-prune --only sequential --exclude cluster --exclude external --max-cases 1",
        "helix.test --no-prune --only cluster --exclude external --max-cases 1",
        "helix.test --no-prune --only external --max-cases 1"
      ],
      "test.unit": [
        "helix.test --no-prune --only unit"
      ],
      "test.cluster": [
        "helix.test --only cluster --exclude sequential",
        "helix.test --no-prune --only sequential --only cluster --max-cases 1"
      ],
      "test.external": [
        "helix.test --only external --exclude cluster --max-cases 1"
      ],
      "test.quick": [
        "helix.test --no-prune --exclude sequential --exclude cluster --exclude external --exclude slow",
      ],
      "pr": [
        "helix.test --exclude sequential --exclude cluster --exclude external",
        "helix.test --no-prune --only sequential --exclude cluster --exclude external --max-cases 1",
        "dialyzer --halt-exit-status",
        "credo --strict"
      ],
      "test.cover": [
        "helix.test --no-prune --exclude sequential --exclude cluster --exclude external --max-cases 1"
      ]
    ]
  end

  defp docs do
    [
      logo: "help/logo.png",
      extras: []
    ]
  end

  defp elixirc_options(:prod) do
    # On prod, don't compile unless no warning is issued
    [warnings_as_errors: true]
  end
  defp elixirc_options(_) do
    # On dev and test, by default, allow to compile even with warnings,
    # unless explicitly told not to
    warnings_as_errors? = System.get_env("HELIX_SKIP_WARNINGS") == "false"

    [warnings_as_errors: warnings_as_errors?]
  end

  defp elixirc_paths(:test),
    do: ["lib", "test/support"]
  defp elixirc_paths(_),
    do: ["lib"]
end
