defmodule HELM.HELFTester.Mixfile do
  use Mix.Project

  def project do
    [app: :helf_tester,
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
    [applications: [:logger, :helf_broker, :helf_router, :account, :entity, :server],
     mod: {HELM.HELFTester.App, []}]
  end

  defp deps do
    [{:helf, git: "ssh://git@git.hackerexperience.com/diffusion/HELF/helf.git", ref: "dev_tester"},
     {:helf_router, in_umbrella: true},
     {:helf_broker, in_umbrella: true},
     {:account, in_umbrella: true},
     {:entity, in_umbrella: true},
     {:server, in_umbrella: true}]
  end
end
