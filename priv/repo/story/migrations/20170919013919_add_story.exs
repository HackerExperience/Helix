defmodule Helix.Story.Repo.Migrations.AddStory do
  use Ecto.Migration

  def change do
    create table(:story_steps, primary_key: false) do
      add :entity_id,
        references(
          :entities,
          column: :entity_id,
          type: :inet),
        primary_key: true
      add :step_id, :string, primary_key: true

      add :meta, :jsonb
      add :emails_sent, {:array, :string}, default: []
      add :allowed_replies, {:array, :string}, default: []
    end

    create table(:story_emails, primary_key: false) do
      add :entity_id,
        references(
          :entities,
          column: :entity_id,
          type: :inet),
        primary_key: true
      add :contact_id, :string, primary_key: true

      add :emails, {:array, :jsonb}, default: []
    end
  end
end
