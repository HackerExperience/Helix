defmodule HELM.Entity.Mixfile do
  use Mix.Project

  def project do
    [app: :entity,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :ecto, :postgrex, :he_broker],
     mod: {HELM.Entity.App, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:he_broker, git: "ssh://git@git.hackerexperience.com/diffusion/BROKER/HEBroker.git"},
     {:helf, git: "ssh://git@git.hackerexperience.com/diffusion/HELF/helf.git", tag: "v1.1.0"},
     {:postgrex, ">= 0.0.0"},
     {:ecto, "~> 2.0"}]
  end
end
