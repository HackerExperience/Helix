defmodule Helix.Story.Event.Handler.StoryTest do

  use Helix.Test.Case.Integration

  alias Helix.Event
  alias Helix.Story.Model.Step
  alias Helix.Story.Query.Story, as: StoryQuery

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "handling of ReplySent events" do
    test "event is pattern matched correctly" do
      {_, %{step: step}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      event = EventSetup.story_reply_sent(step, "reply_to_e1", "e1")

      assert_raise RuntimeError, "replied_to_e1", fn ->
        Event.emit(event)
      end
    end

    test "unregistered event isn't matched" do
      {_, %{step: step}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      event = EventSetup.story_reply_sent(step, "invalid_reply", "e1")

      # Nothing happens...
      Event.emit(event)
    end
  end

  describe "handling of completion events" do
    test "proceeds to the next step" do
      {_, %{entity_id: entity_id, step: step}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      event = EventSetup.story_reply_sent(step, "reply_to_e3", "e3")

      Event.emit(event)

      %{object: new_step} = StoryQuery.fetch_current_step(entity_id)

      refute new_step == step
      assert new_step.name == Step.get_next_step(step)

      :timer.sleep(50)
    end
  end
end
