defmodule Helix.Software.Repo.Migrations.AddVirus do
  use Ecto.Migration

  def change do
    create table(:viruses, primary_key: false) do
      add :file_id,
        references(
          :files, column: :file_id, type: :inet, on_delete: :delete_all
        ),
        primary_key: true

      add :entity_id, :inet, null: false
      add :storage_id,
        references(
          :storages, column: :storage_id, type: :inet, on_delete: :delete_all
        ),
        null: false
    end

    # Identify all viruses installed on a given storage (used by AV)
    create index(:viruses, [:storage_id])

    # Identify all viruses installed by a given entity (used by Database)
    create index(:viruses, [:entity_id])

    create table(:viruses_active, primary_key: false) do
      add :virus_id,
        references(
          :viruses, column: :file_id, type: :inet, on_delete: :delete_all
        ),
        primary_key: true

      add :entity_id, :inet, null: false
      add :storage_id,
        references(
          :storages, column: :storage_id, type: :inet, on_delete: :delete_all
        ),
        null: false
    end

    # {entity_id, storage_id} is UNIQUE because one entity can have at most ONE
    # *active* virus on the victim (identified by storage).
    create index(:viruses_active, [:entity_id, :storage_id], unique: true)
  end
end
