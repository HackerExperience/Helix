defmodule Helix.NPC.Repo.Migrations.InitialSetup do
  use Ecto.Migration

  def change do
    create table(:npcs, primary_key: false) do
      add :npc_id, :inet, primary_key: true

      timestamps()
    end
  end
end
