defmodule Helix.Software.Repo.Migrations.CreateStorageTables do
  use Ecto.Migration

  def change do
    create table(:storages, primary_key: false) do
      add :storage_id, :string, primary_key: true

      timestamps()
    end

    create table(:storage_drives, primary_key: false) do
      add :drive_id, :integer, primary_key: true
      add :storage_id, references(:storages, column: :storage_id, type: :string), null: false

      timestamps()
    end

    create unique_index(:storage_drives, [:storage_id])
  end
end
