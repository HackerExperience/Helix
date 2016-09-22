defmodule HELFRouter.Mixfile do
  use Mix.Project

  def project do
    [app: :helf_router,
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
    [applications: [:logger, :cowboy],
     mod: {HELFRouter.App, []}]
  end

  defp deps do
    [{:helf, git: "ssh://git@git.hackerexperience.com/diffusion/HELF/helf.git", tag: "v2.0.0"},
     {:cowboy,"~> 1.0"}]
  end
end
