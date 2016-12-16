defmodule HELM.Entity.Repo.Migrations.CreateEntityAccountsTable do
  use Ecto.Migration

  def change do
    create table(:entity_accounts) do
      add :entity_id, references(:entities, column: :entity_id, type: :inet), primary_key: true
    end
  end
end
