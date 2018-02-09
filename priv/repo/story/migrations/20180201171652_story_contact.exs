defmodule Helix.Story.Repo.Migrations.StoryContact do
  use Ecto.Migration

  def change do
    drop table(:story_steps)
    drop table(:story_emails)

    create table(:story_steps, primary_key: false) do
      add :entity_id, :inet, primary_key: true
      add :contact_id, :string, primary_key: true

      add :step_name, :string, null: false
      add :meta, :jsonb, null: false, default: fragment("'{}'::json")

      add :emails_sent, {:array, :string}, null: false, default: []
      add :allowed_replies, {:array, :string}, null: false, default: []
    end

    create table(:story_emails, primary_key: false) do
      add :entity_id, :inet, primary_key: true
      add :contact_id, :string, primary_key: true

      add :emails, {:array, :jsonb}, null: false, default: []
    end

    # Apparently Ecto does not work well with composite FKs
    # https://elixirforum.com/t/does-ecto-supports-composite-foreign-keys/2466
    execute """
    ALTER TABLE story_emails
      ADD CONSTRAINT story_emails_fkey
        FOREIGN KEY (entity_id, contact_id)
        REFERENCES story_steps(entity_id, contact_id)
        ON DELETE CASCADE
    """
  end
end
