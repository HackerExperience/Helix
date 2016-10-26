defmodule HELM.Account.Mixfile do
  use Mix.Project

  def project do
    [
      app: :account,
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
    [
      applications: applications(Mix.env),
      mod: {HELM.Account.App, []}]
  end

  defp applications(_),
    do: [:logger, :helf_broker, :helf_router, :ecto, :postgrex, :comeonin]

  defp deps do
    [
      {:helf_router, in_umbrella: true},
      {:helf_broker, in_umbrella: true},
      {:hell, in_umbrella: true},
      {:comeonin, "~> 2.5"},
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 2.0"},
      {:poison, "~> 2.0"}]
  end
end