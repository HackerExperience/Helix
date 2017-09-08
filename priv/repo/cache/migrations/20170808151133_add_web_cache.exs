defmodule Helix.Cache.Repo.Migrations.AddWebCache do
  use Ecto.Migration

  def change do
    create table(:web_cache, primary_key: false) do
      add :network_id,
        :inet,
        primary_key: true
      add :ip,
        :inet,
        primary_key: true
      add :content,
        :json
      add :expiration_date,
        :utc_datetime
    end
    create index(:web_cache, [:expiration_date])
  end
end
