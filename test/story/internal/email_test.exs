defmodule Helix.Story.Internal.EmailTest do

  use Helix.Test.Case.Integration

  alias Helix.Story.Internal.Email, as: EmailInternal

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "fetch/2" do
    test "returns row if it exists" do
      {_, related} = StorySetup.send_email()

      email_id = related.email_id
      entity_id = related.entity_id
      contact_id = related.contact_id

      # Return result from DB
      entry = EmailInternal.fetch(entity_id, contact_id)

      # Ensure it has valid entity/contact information
      assert entry.entity_id == entity_id
      assert entry.contact_id == contact_id

      # And that it finds our recently sent email
      email = Enum.find(entry.emails, &(&1.id == email_id))

      assert email.id == email_id
      assert email.sender
      assert email.timestamp
      assert email.meta
    end

    test "returns nil if no {entity,contact} entry was found" do
      refute EmailInternal.fetch(EntityHelper.id(), :contact_id)
    end
  end

  describe "get_emails/1" do
    test "returns all emails from entity" do
      {generated_entries, %{entity_id: entity_id}} =
        StorySetup.lots_of_emails_and_contacts()

      all_emails = EmailInternal.get_emails(entity_id)

      assert Enum.sort(all_emails) == Enum.sort(generated_entries)
    end
  end

  describe "send_email/3" do
    test "email is persisted correctly on database" do
      {_, %{step: step, entity_id: entity_id}} = StorySetup.story_step()

      email_id = "email_id"

      # Send email for the first time (contact must be created first)
      assert {:ok, story_email, _} =
        EmailInternal.send_email(step, email_id, %{})
      assert story_email.entity_id == entity_id

      # Verify the email was sent with the correct data
      sent_email = Enum.find(story_email.emails, &(&1.id == email_id))
      assert sent_email.id == email_id
      assert sent_email.sender == :contact
      assert sent_email.timestamp

      # It's been persisted into the database
      db_entry = EmailInternal.fetch(entity_id, story_email.contact_id)
      assert db_entry

      # And the saved email data is correct as well
      db_sent_email = Enum.find(db_entry.emails, &(&1.id == email_id))
      assert db_sent_email == sent_email
    end
  end

  describe "send_reply/2" do
    test "reply is persisted correctly on database" do
      {_, %{step: step, entity_id: entity_id}} = StorySetup.story_step()

      reply_id = "reply_id"

      # Send reply for the first time (contact must be created first)
      assert {:ok, story_email, _} = EmailInternal.send_reply(step, reply_id)
      assert story_email.entity_id == entity_id

      # Verify the reply was sent with the correct data
      sent_reply = Enum.find(story_email.emails, &(&1.id == reply_id))
      assert sent_reply.id == reply_id
      assert sent_reply.sender == :player
      assert sent_reply.timestamp

      # It's been persisted into the database
      db_entry = EmailInternal.fetch(entity_id, story_email.contact_id)
      assert db_entry

      # And the saved reply data is correct as well
      db_sent_reply = Enum.find(db_entry.emails, &(&1.id == reply_id))
      assert db_sent_reply == sent_reply
    end
  end
end
