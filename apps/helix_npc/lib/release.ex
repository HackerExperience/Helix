defmodule Helix.NPC.Release do
  alias Helix.NPC.Repo

  def migrate do
    Application.load(:npc)
    {:ok, _} = Application.ensure_all_started(:ecto)
    {:ok, _} = Repo.__adapter__.ensure_all_started(Repo, :temporary)
    {:ok, _} = Repo.start_link(pool_size: 1)

    path = Application.app_dir(:npc, "priv/repo/migrations")

    Ecto.Migrator.run(Repo, path, :up, all: true)

    :init.stop()
  end
end
