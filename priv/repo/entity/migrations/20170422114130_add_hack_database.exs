defmodule Helix.Entity.Repo.Migrations.AddHackDatabase do
  use Ecto.Migration

  def change do
    create table(:database_entries, primary_key: false) do
      add :entity_id, references(:entities, column: :entity_id, type: :inet, on_delete: :delete_all, on_update: :update_all), primary_key: true
      add :network_id, :inet, primary_key: true
      add :server_ip, :inet, primary_key: true

      add :server_id, :inet, null: false

      add :server_type, :string
      add :password, :string

      add :alias, :string
      add :notes, :text

      # Soft delete for when the target server disconnects for any reason
      add :disabled, :boolean

      timestamps()
    end

    # This is just to quickly remove entries when the target server resets IP or
    # resets password.
    # Review: Index below is probably wrong
    create index(:database_entries, [:server_id, :network_id])
  end
end
