defmodule Helix.Core.Mixfile do

  use Mix.Project

  def project do
    [
      app: :helix_core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()]
  end

  def application do
    [applications: [:logger, :helf_broker, :helf_router, :ecto, :postgrex]]
  end

  defp deps do
    [
      {:helf_broker, in_umbrella: true},
      {:helf_router, in_umbrella: true},
      {:hell, in_umbrella: true},
      {:postgrex, "~> 0.13", override: true},
      {:ecto, "~> 2.1", override: true},
      {:burette, git: "https://github.com/HackerExperience/burette", only: :test}]
  end
end