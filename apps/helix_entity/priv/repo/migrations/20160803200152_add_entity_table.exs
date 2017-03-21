defmodule Entity.Repo.Migrations.AddEntityTable do
  use Ecto.Migration

  def change do
    create table(:entities, primary_key: false) do
      add :account_id, :string
      add :npc_id, :string
      add :clan_id, :string

      timestamps()
    end
  end
end
