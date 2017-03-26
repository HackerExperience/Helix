defmodule Helix.Entity.Release do
  alias Helix.Entity.Repo

  def ecto_create do
    Application.load(:helix_entity)
    {:ok, _} = Application.ensure_all_started(:ecto)

    case Repo.__adapter__.storage_up(Repo.config) do
      :ok ->
        IO.puts "created"
      {:error, :already_up} ->
        IO.puts "already created"
      {:error, term} ->
        raise "error: #{term}"
    end

    :init.stop()
  end

  def ecto_migrate do
    Application.load(:helix_entity)
    {:ok, _} = Application.ensure_all_started(:ecto)
    {:ok, _} = Repo.__adapter__.ensure_all_started(Repo, :temporary)
    {:ok, _} = Repo.start_link(pool_size: 1)

    path = Application.app_dir(:helix_entity, "priv/repo/migrations")

    Ecto.Migrator.run(Repo, path, :up, all: true)

    :init.stop()
  end
end
