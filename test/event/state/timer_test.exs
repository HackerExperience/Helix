defmodule Helix.Event.State.TimerTest do

  use Helix.Test.Case.Integration

  alias Helix.Story.Model.Step
  alias Helix.Story.Query.Story, as: StoryQuery
  alias Helix.Event.State.Timer, as: EventTimer

  alias Helix.Test.Story.Setup, as: StorySetup
  alias Helix.Test.Event.Setup, as: EventSetup

  describe "emit_after/2" do
    test "event is emitted after the specified time" do
      {_, %{entity_id: entity_id, step: cur_step}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      event = EventSetup.Story.reply_sent(cur_step, "reply_to_e3", "e3")

      # We've just asked to emit `event` within 50 ms
      EventTimer.emit_after(event, 50)

      # Meanwhile, let's make sure the current step on the DB hasn't changed.
      assert %{object: step} = StoryQuery.fetch_current_step(entity_id)
      assert step == cur_step

      # Wait for it... needs some extra time because async
      :timer.sleep(80)

      assert %{object: new_step} = StoryQuery.fetch_current_step(entity_id)

      # DB state has changed
      refute new_step == cur_step
      assert new_step.name == Step.get_next_step(step)
    end
  end
end
