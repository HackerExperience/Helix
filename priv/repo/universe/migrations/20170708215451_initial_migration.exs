defmodule Helix.Universe.Repo.Migrations.InitialMigration do
  use Ecto.Migration

  def change do
    create table(:npc_types, primary_key: false) do
      add :npc_type,
        :string,
        primary_key: true
    end

    create table(:npcs, primary_key: false) do
      add :npc_id,
        :inet,
        primary_key: true
      add :npc_type,
        references(
          :npc_types,
          column: :npc_type,
          type: :string)

      timestamps()
    end
  end
end
