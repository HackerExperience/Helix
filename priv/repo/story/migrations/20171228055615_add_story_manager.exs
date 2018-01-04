defmodule Helix.Story.Repo.Migrations.AddStoryManager do
  use Ecto.Migration

  def change do
    create table(:story_manager, primary_key: false) do
      add :entity_id, :inet, primary_key: true

      add :server_id, :inet, null: false
      add :network_id, :inet, null: false
    end
    # No indexes on `server_id`/`network_id` for now, we don't use them (yet)
  end
end
