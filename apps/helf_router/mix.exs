defmodule HELM.HELFRouter.Mixfile do
  use Mix.Project

  def project do
    [
      app: :helf_router,
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
    [
      applications: applications(Mix.env),
      mod: {HELM.HELFRouter.App, []}]
  end

defp applications(_),
  do: [:logger, :cowboy]

  defp deps do
    [
      {:helf, git: "ssh://git@git.hackerexperience.com/diffusion/HELF/helf.git", ref: "dev_tester"},
      {:cowboy,"~> 1.0"}]
  end
end
