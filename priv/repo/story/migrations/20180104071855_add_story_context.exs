defmodule Helix.Story.Repo.Migrations.AddStoryContext do
  use Ecto.Migration

  def change do
    create table(:story_contexts, primary_key: false) do
      add :entity_id, :inet, primary_key: true

      add :context, :map
    end
  end
end
