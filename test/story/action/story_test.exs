defmodule Helix.Story.Action.StoryTest do

  use Helix.Test.Case.Integration

  alias Helix.Story.Action.Story, as: StoryAction
  alias Helix.Story.Action.Flow.Story, as: StoryFlow
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.Story
  alias Helix.Story.Query.Story, as: StoryQuery

  alias Helix.Story.Event.Email.Sent, as: StoryEmailSentEvent
  alias Helix.Story.Event.Reply.Sent, as: StoryReplySentEvent

  alias Helix.Test.Story.Helper, as: StoryHelper
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "send_email/3" do
    test "email is sent and saved on story step/email" do
      {_, %{entity_id: entity_id, step: step}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      contact_id = Step.get_contact(step)

      # `e1` is a valid email id within `fake_steps@test_msg`
      email_id = "e1"

      # Send email for the first time (contact must be created first)
      assert {:ok, [event]} = StoryAction.send_email(step, email_id, %{})

      # Returned event is correct
      assert %StoryEmailSentEvent{} = event
      assert event.entity_id == entity_id
      assert event.step == step
      assert event.email.id == email_id

      # Ensure it got saved on the story step entry
      %{entry: story_step} = StoryQuery.fetch_step(entity_id, contact_id)
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

    test "refuses to send an email that is not registered" do
      {_, %{step: step}} = StorySetup.fake_story_step()

      assert {:error, reason} =
        StoryAction.send_email(step, StoryHelper.email_id(), %{})

      assert reason == {:email, :not_found}
    end
  end

  describe "send_reply/3" do
    test "reply is sent" do
      {_, %{entity_id: entity_id}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      [%{object: step, entry: entry}] = StoryQuery.get_steps(entity_id)
      reply_id = StoryHelper.get_allowed_reply(entry)

      assert {:ok, [event]} = StoryAction.send_reply(step, entry, reply_id)

      assert %StoryReplySentEvent{} = event
      assert event.entity_id == entity_id
      assert event.reply.id == reply_id
      assert event.reply_to == Story.Step.get_current_email(entry)
      assert event.step == step

      [%{entry: new_entry}] = StoryQuery.get_steps(entity_id)

      # The `reply_id` was added to the step's `emails_sent` list
      assert Enum.member?(new_entry.emails_sent, reply_id)

      # And it was removed from the `allowed_replies` list
      refute Enum.member?(new_entry.allowed_replies, reply_id)
    end

    test "reply is removed from allowed_replies after message is sent" do
      {_, %{entity_id: entity_id}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      [%{object: step, entry: entry}] = StoryQuery.get_steps(entity_id)
      reply_id = StoryHelper.get_allowed_reply(entry)

      allowed_before = Story.Step.get_allowed_replies(entry)
      assert {:ok, _event} = StoryAction.send_reply(step, entry, reply_id)

      [%{entry: entry_after}] = StoryQuery.get_steps(entity_id)
      allowed_after = Story.Step.get_allowed_replies(entry_after)

      assert length(allowed_after) == length(allowed_before) - 1
      refute Enum.member?(allowed_after, reply_id)
    end

    test "invalid reply is not sent" do
      {_, %{entity_id: entity_id}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      [%{object: step, entry: entry}] = StoryQuery.get_steps(entity_id)
      reply_id = "this_reply_does_not_exist"

      assert {:error, reason} = StoryAction.send_reply(step, entry, reply_id)
      assert reason == {:reply, :not_found}
    end
  end

  describe "rollback_emails/3" do
    test "returns to specified checkpoint (first element)" do
      {_, %{entity_id: entity_id}} =
        StorySetup.story_step(name: :fake_steps@test_msg_flow, meta: %{})

      [%{object: step}] = StoryQuery.get_steps(entity_id)

      StoryFlow.send_reply(entity_id, step.contact, "reply_to_e1")
      StoryFlow.send_reply(entity_id, step.contact, "reply_to_e2")

      # Story.Step has all five messages (3 emails + 2 replies)
      [%{entry: story_step}] = StoryQuery.get_steps(entity_id)
      assert story_step.emails_sent ==
        ["e1", "reply_to_e1", "e2", "reply_to_e2", "e3"]

      # And there are 5 registered messages (3 emails + 2 replies)
      [emails] = StoryQuery.get_emails(entity_id)
      assert emails.contact_id == step.contact
      assert length(emails.emails) == 5

      # Let's rollback to `e1`
      new_meta = %{"foo" => "bar"}
      assert {:ok, story_step, story_email} =
        StoryAction.rollback_emails(step, "e1", new_meta)

      # Story.Step only has `e1`. `e2` and `e3` argon
      assert story_step.emails_sent == ["e1"]

      # There must be only one email (`e1`). Anything after that was removed
      assert length(story_email.emails) == 1

      # And the email that is left had its metadata updated.
      [message] = story_email.emails

      assert message.id == "e1"
      assert message.meta == new_meta
      assert message.sender == :contact
    end

    # Same test as above ("first element"), but now we'll use as checkpoint
    # a message in the middle of the stack. Seems a small change but it covers
    # many extra edge cases
    test "returns to specified checkpoint (middle element)" do
      {_, %{entity_id: entity_id}} =
        StorySetup.story_step(name: :fake_steps@test_msg_flow, meta: %{})

      [%{object: step}] = StoryQuery.get_steps(entity_id)

      StoryFlow.send_reply(entity_id, step.contact, "reply_to_e1")
      StoryFlow.send_reply(entity_id, step.contact, "reply_to_e2")

      # Story.Step has all five messages (3 emails + 2 replies)
      [%{entry: story_step}] = StoryQuery.get_steps(entity_id)
      assert story_step.emails_sent ==
        ["e1", "reply_to_e1", "e2", "reply_to_e2", "e3"]

      # And there are 5 registered messages (3 emails + 2 replies)
      [emails] = StoryQuery.get_emails(entity_id)
      assert emails.contact_id == step.contact
      assert length(emails.emails) == 5

      # Let's rollback to `e2` (which is in the middle of the "stack"!)
      new_meta = %{"foo" => "bar"}
      assert {:ok, story_step, story_email} =
        StoryAction.rollback_emails(step, "e2", new_meta)

      # Story.Step has `e1` and `e2`. `reply_to_e2` and `e3` argon
      assert story_step.emails_sent == ["e1", "reply_to_e1", "e2"]

      # There are 3 emails on the story. `e1`, `reply_to_e1` and `e2`
      assert length(story_email.emails) == 3

      # And the email that is left had its metadata updated.
      [m1, m2, m3] = story_email.emails

      assert m1.id == "e1"
      assert m2.id == "reply_to_e1"
      assert m3.id == "e2"
      assert m3.meta == new_meta
    end
  end
end
