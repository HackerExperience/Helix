defmodule Helix.Story.Repo.Migrations.RemoveStoryEmailsFK do
  use Ecto.Migration

  def change do
    # Removing the `story_emails` FK because emails are mostly historical, they
    # still exist even if all steps from a specific contact have been completed
    execute """
    ALTER TABLE story_emails
      DROP CONSTRAINT story_emails_fkey
    """
  end
end
