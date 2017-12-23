defmodule Helix.Cache.Repo.Migrations.RemoveDeprecatedCacheColumns do
  use Ecto.Migration

  def change do
    drop index(:server_cache, [:entity_id])
    drop index(:server_cache, [:motherboard_id])
    alter table(:server_cache, primary_key: false) do
      remove :entity_id
      remove :motherboard_id
      remove :resources
      remove :components
    end

    drop table(:component_cache)
  end
end
