defmodule Entity.Repo.Migrations.AddIdsIndex do
  use Ecto.Migration

  def change do
    create index(:entities, [:account_id], unique: true, name: :unique_account_id)
    create index(:entities, [:npc_id], unique: true, name: :unique_npc_id)
    create index(:entities, [:clan_id], unique: true, name: :unique_clan_id)
  end
end
