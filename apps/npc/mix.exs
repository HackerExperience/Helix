defmodule HELM.NPC.Mixfile do
  use Mix.Project

  def project do
    [
      app: :npc,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      elixirc_options: elixirc_options(Mix.env),
      deps: deps]
  end

  def application do
    [
      applications: applications(Mix.env),
      mod: {HELM.NPC.App, []}]
  end

  defp applications(_),
    do: [:helix_core]

  defp elixirc_options(:dev),
    do: []
  defp elixirc_options(_),
    do: [warnings_as_errors: true]

  defp deps do
    [
      {:helix_core, in_umbrella: true}]
  end
end