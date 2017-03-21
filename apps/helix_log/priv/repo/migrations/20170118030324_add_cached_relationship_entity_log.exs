defmodule Helix.Log.Repo.Migrations.AddCachedRelationshipEntityLog do
  use Ecto.Migration

  def change do
    create index(:logs, [:server_id, :inserted_at])

    create table(:log_touches, primary_key: false) do
      add :log_id, references(:logs, column: :log_id, type: :inet, on_delete: :delete_all), primary_key: true
      add :entity_id, :inet, null: false, primary_key: true
    end
  end
end
