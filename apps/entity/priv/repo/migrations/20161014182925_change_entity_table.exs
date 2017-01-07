defmodule Helix.Entity.Repo.Migrations.ChangeEntityTable do
  use Ecto.Migration

  def change do
    drop table(:servers)

    create table(:entity_servers, primary_key: false) do
      add :server_id, :string, primary_key: true
      add :entity_id, references(:entities, column: :entity_id, type: :string)

      timestamps()
    end

    create table(:entity_types, primary_key: false) do
      add :entity_type, :string, primary_key: true

      timestamps()
    end

    alter table(:entities) do
      add :reference_id, :string
      add :entity_type, references(:entity_types, column: :entity_type, type: :string)
      remove :account_id
      remove :npc_id
      remove :clan_id
    end

    create unique_index(:entities, [:reference_id])
  end
end
