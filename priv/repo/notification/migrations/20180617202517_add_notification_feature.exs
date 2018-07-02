defmodule Helix.Notification.Repo.Migrations.AddNotificationFeature do
  use Ecto.Migration

  def change do
    create table(:notifications_account, primary_key: false) do
      add :notification_id, :inet, primary_key: true

      add :account_id, :inet, null: false
      add :code, :integer, null: false
      add :data, :jsonb, null: false
      add :is_read, :boolean, default: false, null: false
      add :creation_time, :utc_datetime, null: false
    end
    create index(:notifications_account, [:account_id])

    create table(:notifications_server, primary_key: false) do
      add :notification_id, :inet, primary_key: true

      add :account_id, :inet, null: false
      add :server_id, :inet, null: false
      add :code, :integer, null: false
      add :data, :jsonb, null: false
      add :is_read, :boolean, default: false, null: false
      add :creation_time, :utc_datetime, null: false
    end
    create index(:notifications_server, [:account_id, :server_id])
  end
end
