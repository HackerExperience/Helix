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

      {reply_step, _} =
        StorySetup.story_step(
          entity_id: entity.entity_id,
          name: :fake_steps@test_msg,
          meta: %{}
        )
      index = StoryIndex.index(entity.entity_id)

      # Ensure all emails (sent/received) are listed correctly
      Enum.each(emails, fn story_email ->
        contact_data = index[story_email.contact_id]

        # Contact was found
        assert contact_data
        assert contact_data.name
        assert contact_data.meta
        assert contact_data.replies

        Enum.each(story_email.emails, fn email ->
          message = find_message(contact_data.emails, email.id)

          # Message was found
          assert message
          assert message.id == email.id
          assert message.timestamp == email.timestamp
          assert message.meta == email.meta
        end)
      end)

      # Ensure replies are ok (on `reply_step`)
      contact_data = index[reply_step.contact_id]

      assert contact_data.name == reply_step.step_name
      assert contact_data.meta == reply_step.meta
      assert contact_data.replies == reply_step.allowed_replies
    end
  end

  describe "render_index/1" do
    test "rendered output is correct and json friendly" do
      {entity, _} = EntitySetup.entity()

      {emails, _} =
        StorySetup.lots_of_emails_and_contacts(entity_id: entity.entity_id)

      rendered =
        entity.entity_id
        |> StoryIndex.index()
        |> StoryIndex.render_index()

      Enum.each(emails, fn story_email ->
        contact_data = rendered[story_email.contact_id]
          # find_contact(rendered.emails, to_string(story_email.contact_id))

        # Contact was found
        assert contact_data
        assert is_binary(contact_data.name)
        assert contact_data.meta
        assert contact_data.replies

        Enum.each(story_email.emails, fn email ->
          message = find_message(contact_data.emails, to_string(email.id))

          # Message was found
          assert message
          assert message.id == email.id
          assert message.timestamp == ClientUtils.to_timestamp(email.timestamp)
          assert message.meta == email.meta
        end)
      end)
    end
  end

  defp find_message(contact_messages, email_id),
    do: Enum.find(contact_messages, &(&1.id == email_id))
end
