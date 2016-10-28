defmodule HELM.Entity.Repo.Migrations.ChangePrimaryKeyType do
  use Ecto.Migration

  def change do
    drop table(:entity_servers)

    alter table(:entities, primary_key: false) do
      remove :reference_id
      remove :entity_id
      add :entity_id, :binary_id, primary_key: true
      add :reference_id, :binary_id
    end

    create table(:entity_servers, primary_key: false) do
      add :server_id, :binary_id, primary_key: true
      add :entity_id, references(:entities, column: :entity_id, type: :binary_id)

      timestamps
    end
  end
end