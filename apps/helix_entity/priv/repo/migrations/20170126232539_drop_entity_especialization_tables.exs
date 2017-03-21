defmodule Helix.Entity.Repo.Migrations.DropEntityEspecializationTables do
  use Ecto.Migration

  def change do
    drop table(:entity_accounts)
    drop table(:entity_npcs)
    drop table(:entity_clans)
  end
end
