defmodule Helix.NPC.Repo.Migrations.ChangePrimaryKeyType do
  use Ecto.Migration

  def change do
    drop unique_index(:npcs, [:npc_id], name: :unique_npc_id)

    alter table(:npcs) do
      remove :npc_id
      add :npc_id, :binary_id, primary_key: true
    end
  end
end