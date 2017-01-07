defmodule Helix.Entity.Repo.Migrations.ChangePkToIp do
  use Ecto.Migration

  def change do
    drop table(:entity_servers)

    alter table(:entities) do
      remove :reference_id
      remove :entity_id
      add :entity_id, :inet, primary_key: true
      add :reference_id, :inet
    end

    create table(:entity_servers, primary_key: false) do
      add :server_id, :inet, primary_key: true
      add :entity_id, references(:entities, column: :entity_id, type: :inet)

      timestamps()
    end
  end
end