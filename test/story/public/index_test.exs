defmodule Helix.Story.Public.IndexTest do

  use Helix.Test.Case.Integration

  alias HELL.ClientUtils
  alias Helix.Story.Public.Index, as: StoryIndex

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "index/1" do
    test "indexes messages correctly" do
      {entity, _} = EntitySetup.entity()

      {emails, _} =
        StorySetup.lots_of_emails_and_contacts(entity_id: entity.entity_id)

      index = StoryIndex.index(entity.entity_id)

      Enum.each(emails, fn story_email ->
        contact_data = find_contact(index.email, story_email.contact_id)

        # Contact was found
        assert contact_data
        assert contact_data.contact_id == story_email.contact_id

        Enum.each(story_email.emails, fn email ->
          message = find_message(contact_data.messages, email.id)

          # Message was found
          assert message
          assert message.id == email.id
          assert message.timestamp == email.timestamp
          assert message.meta == email.meta
        end)
      end)
    end
  end

  describe "render_index/1" do
    test "rendered output is correct and json friendly" do
      {entity, _} = EntitySetup.entity()

      {emails, _} =
        StorySetup.lots_of_emails_and_contacts(entity_id: entity.entity_id)

      index = StoryIndex.index(entity.entity_id)
      rendered = StoryIndex.render_index(index)

      Enum.each(emails, fn story_email ->
        contact_data =
          find_contact(rendered.email, to_string(story_email.contact_id))

        # Contact was found
        assert contact_data
        assert contact_data.contact_id == to_string(story_email.contact_id)

        Enum.each(story_email.emails, fn email ->
          message = find_message(contact_data.messages, to_string(email.id))

          # Message was found
          assert message
          assert message.id == email.id
          assert message.timestamp == ClientUtils.to_timestamp(email.timestamp)
          assert message.meta == email.meta
        end)
      end)
    end
  end

  defp find_contact(index_emails, contact_id),
    do: Enum.find(index_emails, &(&1.contact_id == contact_id))

  defp find_message(contact_messages, email_id),
    do: Enum.find(contact_messages, &(&1.id == email_id))
end
