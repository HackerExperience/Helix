defmodule Helix.Process.Repo.Migrations.InitialSetup do
  use Ecto.Migration

  def change do
    create table(:processes, primary_key: false) do
      add :process_id,
        :inet,
          primary_key: true
      add :gateway_id,
        :inet,
          null: false
      add :target_server_id,
        :inet,
          null: false
      add :file_id,
        :inet
     add :network_id,
        :inet
     add :process_data,
        :jsonb,
          null: false
      add :process_type,
        :string,
          null: false
      add :state,
        :integer,
          null: false
      add :priority,
        :integer,
          null: false
      add :objective,
        :jsonb
     add :processed,
        :jsonb,
          null: false
      add :allocated,
        :jsonb,
          null: false
      add :limitations,
        :jsonb,
          null: false
      add :creation_time,
        :utc_datetime,
          null: false
      add :updated_time,
        :utc_datetime,
          null: false
    end

    create index(:processes, [:gateway_id])

    create table(:process_servers, primary_key: false) do
      add :server_id,
        :inet,
        primary_key: true
      add :process_id,
        references(
          :processes,
          column: :process_id,
          type: :inet,
          on_delete: :delete_all,
          on_update: :nothing),
        primary_key: true
      add :process_type,
        :string,
        null: false
    end

    create index(
      :process_servers,
      [:server_id, :process_type, :process_id],
      name: :process_servers_process_type_on_server_index)
  end
end
