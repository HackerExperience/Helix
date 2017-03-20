defmodule Helix.HELFRouter.Mixfile do
  use Mix.Project

  def project do
    [
      app: :helf_router,
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
      mod: {Helix.HELFRouter.App, []}
    ]
  end

  defp elixirc_options(:dev),
    do: []
  defp elixirc_options(_),
    do: [warnings_as_errors: true]

  defp deps do
    [
      {:helf, git: "https://github.com/HackerExperience/HELF.git"},
      {:cowboy,"~> 1.0"}
    ]
  end
end
