defmodule Helix.Log.Repo.Migrations.LogRewrite do
  use Ecto.Migration

  def change do
    drop table(:log_touches)
    drop table(:revisions)
    drop table(:logs)

    create table(:logs, primary_key: false) do
      add :log_id, :inet, primary_key: true

      add :revision_id, :integer, null: false
      add :server_id, :inet, null: false

      add :creation_time, :utc_datetime, null: false
    end
    create index(:logs, [:server_id, :creation_time])

    create table(:log_revisions, primary_key: false) do
      add :log_id,
        references(:logs, column: :log_id, type: :inet, on_delete: :delete_all),
        primary_key: true

      add :revision_id, :integer, primary_key: true

      add :type, :integer, null: false
      add :data, :jsonb, null: false

      add :entity_id, :inet, null: false
      add :forge_version, :integer

      add :creation_time, :utc_datetime, null: false
    end
  end
end
