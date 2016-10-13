defmodule HELM.Entity.Repo.Migrations.CreateServersTable do
  use Ecto.Migration

  def change do
    create table(:servers, primary_key: false) do
      add :server_id, :string, primary_key: true
      add :entity_id, references(:entities, column: :entity_id, type: :string)

      timestamps
    end
  end
end
