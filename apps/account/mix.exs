defmodule Helix.Account.Mixfile do
  use Mix.Project

  def project do
    [
      app: :account,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      elixirc_options: elixirc_options(Mix.env),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Helix.Account.App, []}
    ]
  end

  defp elixirc_options(:dev),
    do: []
  defp elixirc_options(_),
    do: [warnings_as_errors: true]

  defp deps do
    [
      {:helix_core, in_umbrella: true},
      {:comeonin, "~> 2.5"},
      {:poison, "~> 2.0"},
      {:guardian, "~> 0.14"},
      {:burette, git: "https://github.com/HackerExperience/burette", only: :test}
    ]
  end
end