defmodule Account.Mixfile do
  use Mix.Project

  alias HELM.Account

  def project do
    [app: :account,
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
    [applications: [:framework, :logger, :ecto, :postgrex, :auth],
     mod: {Account.App, []}]
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
    [{:framework, in_umbrella: true},
     {:hell, in_umbrella: true},
     {:auth, in_umbrella: true},
     {:postgrex, ">= 0.0.0"},
     {:ecto, "~> 2.0"},
     {:poison, "~> 2.0"}] # TODO: add guardian
  end
end
