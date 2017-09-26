defmodule Helix.Story.Model.MacroTest do

  use Helix.Test.Case.Integration

  alias Helix.Story.Event.Email.Sent, as: StoryEmailSentEvent
  alias Helix.Story.Model.Steppable

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "on_reply" do
    test "it pattern-matches correctly" do
      {_, %{step: step}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      # reply_to_e1 tests the `do` block
      r1_event = EventSetup.story_reply_sent(step, "reply_to_e1", "e1")

      assert_raise RuntimeError, "replied_to_e1", fn ->
        Steppable.handle_event(step, r1_event, %{})
      end

      # reply_to_e2 tests the `send` block
      r2_event = EventSetup.story_reply_sent(step, "reply_to_e2", "e2")

      {action, _, [event]} = Steppable.handle_event(step, r2_event, %{})

      assert action == :noop
      assert %StoryEmailSentEvent{} = event
      assert event.email_id == "e3"

      # reply_to_e3 tests the `complete` block
      r3_event = EventSetup.story_reply_sent(step, "reply_to_e3", "e3")

      {action, _, []} = Steppable.handle_event(step, r3_event, %{})
      assert action == :complete

      # Below events test the case where no pattern is matched
      unmatched_reply_event =
        EventSetup.story_reply_sent(step, "reply_to_e3", "e1")

      assert {:noop, _, []} =
        Steppable.handle_event(step, unmatched_reply_event, %{})

      invalid_reply_event =
        EventSetup.story_reply_sent(step, "not_exists", "e3")

      assert {:noop, _, []} =
        Steppable.handle_event(step, invalid_reply_event, %{})
    end
  end
end
