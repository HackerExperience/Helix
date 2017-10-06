defmodule Helix.Log.Repo.Migrations.ChangeLogTimestamps do
  use Ecto.Migration

  def change do
    alter table(:logs) do
      remove :inserted_at
      remove :updated_at

      add :creation_time, :utc_datetime, null: false, default: fragment("now()")
    end

    create index(:logs, [:server_id, :creation_time])

    alter table(:revisions) do
      remove :inserted_at

      add :creation_time, :utc_datetime, null: false, default: fragment("now()")
    end
  end
end
