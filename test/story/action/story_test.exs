defmodule Helix.Story.Action.StoryTest do

  use Helix.Test.Case.Integration

  alias Helix.Story.Action.Story, as: StoryAction
  alias Helix.Story.Event.Email.Sent, as: StoryEmailSentEvent
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.StoryStep
  alias Helix.Story.Query.Story, as: StoryQuery

  alias Helix.Test.Story.Setup, as: StorySetup

  describe "send_email/3" do
    test "email is sent and saved on story step/email" do
      {_, %{entity_id: entity_id, step: step}} = StorySetup.story_step()

      contact_id = Step.get_contact(step)
      email_id = "email_id"

      # Send email for the first time (contact must be created first)
      assert {:ok, [event]} = StoryAction.send_email(step, email_id, %{})

      # Returned event is correct
      assert %StoryEmailSentEvent{} = event
      assert event.email_id == email_id
      assert event.entity_id == entity_id
      assert event.step == step.name
      assert event.timestamp
      assert event.meta

      # Ensure it got saved on the story step entry
      %{entry: story_step} = StoryQuery.fetch_current_step(entity_id)
      assert Enum.member?(story_step.emails_sent, email_id)

      # And it's also on the story_email entry
      contact =
        entity_id
        |> StoryQuery.get_emails()
        |> Enum.filter(&(&1.contact_id == contact_id))
        |> List.first()

      email =
        contact.emails
        |> Enum.filter(&(&1.id == email_id))
        |> List.first()

      assert email
    end
  end

  describe "send_reply/3" do
    test "reply is sent" do
      {_, %{entity_id: entity_id}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      %{object: step, entry: entry} = StoryQuery.fetch_current_step(entity_id)
      reply_id = get_allowed_reply(entry)

      assert {:ok, [event]} = StoryAction.send_reply(step, entry, reply_id)

      # assert %StoryReplySentEvent{} = event
      assert event.entity_id == entity_id
      assert event.reply_id == reply_id
      assert event.reply_to == StoryStep.get_current_email(entry)
      assert event.timestamp
      assert event.step == step.name
    end

    test "reply is removed from allowed_replies after message is sent" do
      {_, %{entity_id: entity_id}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      %{object: step, entry: entry} = StoryQuery.fetch_current_step(entity_id)
      reply_id = get_allowed_reply(entry)

      allowed_before = StoryStep.get_allowed_replies(entry)
      assert {:ok, _event} = StoryAction.send_reply(step, entry, reply_id)

      %{entry: entry_after} = StoryQuery.fetch_current_step(entity_id)
      allowed_after = StoryStep.get_allowed_replies(entry_after)

      assert length(allowed_after) == length(allowed_before) - 1
      refute Enum.member?(allowed_after, reply_id)

    end

    test "invalid reply is not sent" do
      {_, %{entity_id: entity_id}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      %{object: step, entry: entry} = StoryQuery.fetch_current_step(entity_id)
      reply_id = "this_reply_does_not_exist"

      assert {:error, reason} = StoryAction.send_reply(step, entry, reply_id)
      assert reason == {:reply, :not_found}
    end

    defp get_allowed_reply(entry) do
      entry
      |> StoryStep.get_allowed_replies()
      |> Enum.random()
    end
  end
end
