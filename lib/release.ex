defmodule Helix.Release do

  def ecto_create do
    start_applications()

    execute_on_all_repos(fn repo ->
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
    start_applications()
    start_repos()

    execute_on_all_repos(fn repo ->
      priv = Application.get_env(:helix, repo)[:priv]
      path = Application.app_dir(:helix, priv <> "/migrations")

      Ecto.Migrator.run(repo, path, :up, all: true)
    end)

    :init.stop()
  end

  def seeds do
    start_applications()
    start_repos()
    start_cache()

    :helix
    |> Application.app_dir("priv/**/seeds.exs")
    |> Path.wildcard()
    |> Enum.each(&Code.require_file/1)

    :init.stop()
  end

  defp start_applications do
    Application.load(:helix)

    {:ok, _} = Application.ensure_all_started(:ecto)
  end

  defp start_repos do
    execute_on_all_repos(fn repo ->
      {:ok, _} = repo.__adapter__.ensure_all_started(repo, :temporary)
      {:ok, _} = repo.start_link(pool_size: 1)
    end)
  end

  # HACK: Some seed functions use cache implicitly, and as such require it
  # to be started. That's what we do here. A better fix would be to disable
  # cache altogether, by adding something like a `SKIP_CACHE` flag.
  defp start_cache,
    do: Helix.Cache.State.Supervisor.start_link()

  defp execute_on_all_repos(fun) when is_function(fun, 1) do
    :helix
    |> Application.get_env(:ecto_repos)
    |> Enum.each(fun)
  end
end
