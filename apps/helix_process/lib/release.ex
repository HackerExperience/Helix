defmodule Helix.Process.Release do
  alias Helix.Process.Repo

  def migrate do
    Application.load(:helix_process)
    {:ok, _} = Application.ensure_all_started(:ecto)
    {:ok, _} = Repo.__adapter__.ensure_all_started(Repo, :temporary)
    {:ok, _} = Repo.start_link(pool_size: 1)

    path = Application.app_dir(:helix_process, "priv/repo/migrations")

    Ecto.Migrator.run(Repo, path, :up, all: true)

    :init.stop()
  end
end
