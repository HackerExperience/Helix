defmodule HELM.Entity.Repo.Migrations.CreateNpcAndClanSpecializationTables do
  use Ecto.Migration

  def change do
    alter table(:entity_accounts) do
      remove :entity_id
      add :entity_id, references(:entities, column: :entity_id, type: :inet, on_delete: :delete_all), primary_key: true
    end
    create table(:entity_npcs) do
      add :entity_id, references(:entities, column: :entity_id, type: :inet, on_delete: :delete_all), primary_key: true
    end
    create table(:entity_clans) do
      add :entity_id, references(:entities, column: :entity_id, type: :inet, on_delete: :delete_all), primary_key: true
    end
  end
end