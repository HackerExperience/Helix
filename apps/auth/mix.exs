defmodule HELM.Auth.Mixfile do
  use Mix.Project

  def project do
    [app: :auth,
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

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger],
     mod: {HELM.Auth.App, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:guardian, "~> 0.12.0"},
      {:account, in_umbrella: true},
      {:he_broker, git: "ssh://git@git.hackerexperience.com/diffusion/BROKER/HEBroker.git"},
      {:helf, git: "ssh://git@git.hackerexperience.com/diffusion/HELF/helf.git", tag: "v1.0.0"}
    ]
  end
end
