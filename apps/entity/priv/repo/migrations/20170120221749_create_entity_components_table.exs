defmodule Helix.Entity.Repo.Migrations.CreateEntityComponentsTable do
  use Ecto.Migration

  def change do
    create table(:entity_components) do
      add :entity_id, references(:entities, column: :entity_id, type: :inet, on_delete: :delete_all), primary_key: true
      add :component_id, :inet, primary_key: true
    end
  end
end