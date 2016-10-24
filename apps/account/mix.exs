defmodule Account.Mixfile do
  use Mix.Project

  alias HELM.Account

  def project do
    [app: :account,
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
    [applications: applications(Mix.env),
     mod: {Account.App, []}]
  end

  defp applications(:dev), do: default_applications ++ [:remix]
  defp applications(_), do: default_applications()
  defp default_applications, do: [:logger, :helf_broker, :helf_router, :ecto, :postgrex, :auth]

  defp deps do
    [{:helf_router, in_umbrella: true},
     {:helf_broker, in_umbrella: true},
     {:hell, in_umbrella: true},
     {:auth, in_umbrella: true},
     {:postgrex, ">= 0.0.0"},
     {:ecto, "~> 2.0"},
     {:poison, "~> 2.0"},
     {:remix, "~> 0.0.1", only: :dev}]
  end
end
