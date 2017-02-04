defmodule Helix.Process.Repo.Migrations.UpdateProcessAddNetworkId do
  use Ecto.Migration

  def change do
    alter table(:processes) do
      remove :inserted_at
      remove :updated_at

      add :gateway_id, :inet,
        null: false
      add :target_server_id, :inet,
        null: false
      add :file_id, :inet
      add :network_id, :inet

      add :software, :jsonb,
        null: false
      add :software_type, :string,
        null: false

      add :state, :integer,
        null: false
      add :priority, :integer,
        null: false

      add :objective, :jsonb
      add :processed, :jsonb,
        null: false
      add :allocated, :jsonb,
        null: false
      add :limitations, :jsonb,
        null: false

      add :creation_time, :utc_datetime,
        null: false
      add :updated_time, :utc_datetime,
        null: false
    end

    create index(:processes, [:gateway_id])

    # TODO: A better name would be nice i guess
    create table(:server_process_maps, primary_key: false) do
      add :server_id, :inet,
        primary_key: true
      add :process_id, references(:processes, column: :process_id, type: :inet, on_delete: :delete_all, on_update: :nothing),
        primary_key: true
      add :software_type, :string,
        null: false
    end

    create index(:server_process_maps, [:server_id, :software_type, :process_id], name: :server_process_maps_software_type_on_server_index)
  end
end
