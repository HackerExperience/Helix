defmodule Helix.Software.Repo.Migrations.UniqueStorageDrives do
  use Ecto.Migration

  def change do
    create unique_index(:storage_drives, [:drive_id])
  end
end
