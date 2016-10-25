defmodule HELL.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hell,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      elixirc_paths: compile_paths(Mix.env),
      deps: deps]
  end

  def application do
    [applications: applications(Mix.env)]
  end

  defp applications(_),
    do: default_applications()
  defp applications(:test),
    do: default_applications() ++ [:remix]
  defp default_applications,
    do: [:logger]

  defp compile_paths(:test),
    do: ["lib", "test/helper"]
  defp compile_paths(_),
    do: ["lib"]

  defp deps do
    [
      {:uuid, "~> 1.1"},
      {:remix, "~> 0.0.1", only: :dev}]
  end
end
