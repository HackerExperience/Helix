defmodule Helix.Software.Repo.Migrations.FixSoftwareDrivePk do
  use Ecto.Migration

  def change do
    alter table(:storages) do
      remove :inserted_at
      remove :updated_at
    end

    alter table(:storage_drives) do
      remove :storage_id
      remove :drive_id
      remove :inserted_at
      remove :updated_at

      add :storage_id, references(:storages, column: :storage_id, type: :inet, on_delete: :delete_all), primary_key: true
      add :drive_id, :integer, primary_key: true
      add :hardware_id, :inet
    end

    create unique_index(:storage_drives, [:hardware_id], name: :storage_drives_hardware_id_unique_index)
  end
end
