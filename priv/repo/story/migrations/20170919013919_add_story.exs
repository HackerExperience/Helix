defmodule Helix.Story.Repo.Migrations.AddStory do
  use Ecto.Migration

  def change do
    # Rewritten at `StoryContact` migration
    create table(:story_steps, primary_key: false) do
      add :entity_id, :inet, primary_key: true
      add :step_name, :string, primary_key: true

      add :meta, :jsonb
      add :emails_sent, {:array, :string}, default: []
      add :allowed_replies, {:array, :string}, default: []
    end

    # Rewritten at `StoryContact` migration
    create table(:story_emails, primary_key: false) do
      add :entity_id, :inet, primary_key: true
      add :contact_id, :string, primary_key: true

      add :emails, {:array, :jsonb}, default: []
    end
  end
end
