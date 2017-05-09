defmodule Helix.Release do

  def ecto_create do
    Application.load(:helix)
    {:ok, _} = Application.ensure_all_started(:ecto)

    repos = Application.get_env(:helix, :ecto_repos)

    Enum.each(repos, fn repo ->
      case repo.__adapter__.storage_up(repo.config) do
        :ok ->
          IO.puts "created"
        {:error, :already_up} ->
          IO.puts "already created"
        {:error, term} ->
          raise "error: #{term}"
      end
    end)

    :init.stop()
  end

  def ecto_migrate do
    Application.load(:helix)

    repos = Application.get_env(:helix, :ecto_repos)

    {:ok, _} = Application.ensure_all_started(:ecto)

    Enum.each(repos, fn repo ->
      {:ok, _} = repo.__adapter__.ensure_all_started(repo, :temporary)
      {:ok, _} = repo.start_link(pool_size: 1)
    end)

    Enum.each(repos, fn repo ->
      priv = Application.get_env(:helix, repo)[:priv]
      path = Application.app_dir(:helix, priv <> "/migrations")

      Ecto.Migrator.run(repo, path, :up, all: true)
    end)

    :init.stop()
  end

  def seeds do
    Application.load(:helix)

    repos = Application.get_env(:helix, :ecto_repos)

    {:ok, _} = Application.ensure_all_started(:ecto)

    Enum.each(repos, fn repo ->
      {:ok, _} = repo.__adapter__.ensure_all_started(repo, :temporary)
      {:ok, _} = repo.start_link(pool_size: 1)
    end)

    :helix
    |> Application.app_dir("priv/**/seeds.exs")
    |> Path.wildcard()
    |> Enum.each(&Code.require_file/1)

    :init.stop()
  end
end
