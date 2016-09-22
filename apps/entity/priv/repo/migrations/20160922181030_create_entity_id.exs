defmodule HELM.Entity.Repo.Migrations.CreateEntityId do
  use Ecto.Migration

  def change do
    alter table(:entities) do
      add :entity_id, :string, primary_key: true
    end
  end
end
