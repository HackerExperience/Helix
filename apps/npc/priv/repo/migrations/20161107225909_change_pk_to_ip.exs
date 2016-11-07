defmodule HELM.NPC.Repo.Migrations.ChangePkToIp do
  use Ecto.Migration

  def change do
    alter table(:npcs) do
      remove :npc_id
      add :npc_id, :inet, primary_key: true
    end
  end
end