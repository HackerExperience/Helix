defmodule HELM.NPC.Repo.Migrations.CreateNpcTable do
  use Ecto.Migration

  def change do
    create table(:npcs, primary_key: false) do
      add :npc_id, :string, primary_key: true

      timestamps
    end
    create unique_index(:npcs, [:npc_id], name: :unique_npc_id)
  end
end