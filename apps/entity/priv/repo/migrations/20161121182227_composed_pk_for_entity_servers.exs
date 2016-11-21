defmodule HELM.Entity.Repo.Migrations.ComposedPkForEntityServers do
  use Ecto.Migration

  def change do
    alter table(:entity_servers) do
      remove :server_id
      remove :entity_id
      add :server_id, :inet, primary_key: true
      add :entity_id, references(:entities, column: :entity_id, type: :inet), primary_key: true
    end
  end
end