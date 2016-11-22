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
      deps: deps]
  end

  def application do
    [applications: [:logger, :helf_broker, :helf_router, :ecto, :postgrex]]
  end

  defp deps do
    [
      {:helf_broker, in_umbrella: true},
      {:helf_router, in_umbrella: true},
      {:hell, in_umbrella: true},
      {:postgrex, "~> 1.0-rc", override: true},
      # {:ecto, "~> 2.1.0-rc.4", git: "https://github.com/elixir-ecto/ecto.git", tag: "v2.1.0-rc.4"},
      {:ecto, "~> 2.1.0-rc.4", override: true},
      {:ecto_network, "~> 0.4.0"}]
  end
end