defmodule Helix.Cache.Repo.Migrations.InitialMigration do
  use Ecto.Migration

  def change do

    create table(:server_cache, primary_key: false) do
      add :server_id, :inet, primary_key: true
      add :entity_id, :inet
      add :motherboard_id, :inet
      add :networks, {:array, :json}
      add :storages, {:array, :inet}
      add :resources, :map
      add :components, {:array, :inet}
      add :expiration_date, :utc_datetime
    end
    create index(:server_cache, [:entity_id])
    create index(:server_cache, [:motherboard_id])
    create index(:server_cache, [:expiration_date])

    create table(:storage_cache, primary_key: false) do
      add :storage_id, :inet, primary_key: true
      add :server_id, :inet
      add :expiration_date, :utc_datetime
    end
    create index(:storage_cache, [:expiration_date])

    create table(:network_cache, primary_key: false) do
      add :network_id, :inet, primary_key: true
      add :ip, :inet, primary_key: true
      add :server_id, :inet
      add :expiration_date, :utc_datetime
    end
    create index(:network_cache, [:expiration_date])

    create table(:component_cache, primary_key: false) do
      add :component_id, :inet, primary_key: true
      add :motherboard_id, :inet
      add :expiration_date, :utc_datetime
    end
    create index(:component_cache, [:expiration_date])

    create table(:web_cache, primary_key: false) do
      add :network_id, :inet, primary_key: true
      add :ip, :inet, primary_key: true
      add :content, :json
      add :expiration_date, :utc_datetime
    end
    create index(:web_cache, [:expiration_date])
  end
end
