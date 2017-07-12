defmodule Helix.Network.Repo.Migrations.Webserver do
  use Ecto.Migration

  def change do
    create table(:webservers, primary_key: false) do
      add :ip, :inet, primary_key: true
      add :content, :string, size: 2048
    end

    create table(:webserver_npc_cache, primary_key: false) do
      add :ip, :inet, primary_key: true
      add :npc_id, :inet, null: false
      add :content, :map, null: false
      add :expiration_time, :utc_datetime, default: fragment("now()")
    end

    create unique_index(:webserver_npc_cache, [:npc_id])
    create index(:webserver_npc_cache, [:expiration_time])
    end
end
