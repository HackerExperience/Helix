defmodule Helix.Entity.Repo.Migrations.AddDatabaseVirus do
  use Ecto.Migration

  def change do
    # UNIQUE index on `server_id` required for FK purposes
    create unique_index(:entity_servers, [:server_id])

    create table(:database_viruses, primary_key: false) do
      add :entity_id,
        references(:entities, column: :entity_id, type: :inet),
        primary_key: true
      add :server_id,
        references(:entity_servers, column: :server_id, type: :inet),
        primary_key: true
      add :file_id, :inet, primary_key: true
    end

    create unique_index(:database_viruses, [:file_id])
  end
end
