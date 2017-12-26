defmodule Helix.Story.Event.Handler.StoryTest do

  use Helix.Test.Case.Integration

  import ExUnit.CaptureLog

  alias Helix.Story.Model.Step
  alias Helix.Story.Query.Story, as: StoryQuery

  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "handling of EntityCreatedEvent" do
    test "storyline is set up properly" do
      event = %{entity: entity} = EventSetup.Entity.created(source: :account)

      # Entity not part of any story_step
      refute StoryQuery.fetch_current_step(entity.entity_id)

      # Emit `EntityCreatedEvent`, which should lead to the setup of the
      # storyline for this entity
      EventHelper.emit(event)

      # Entity is part of a step now
      assert %{entry: _story_step, object: step} =
        StoryQuery.fetch_current_step(entity.entity_id)

      # Which happens to be the first one
      assert step.name == Step.first_step_name()
    end
  end

  describe "handling of ReplySent events" do
    test "event is pattern matched correctly" do
      {_, %{step: step}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      event = EventSetup.Story.reply_sent(step, "reply_to_e1", "e1")

      assert capture_log(fn ->
        EventHelper.emit(event)
      end) =~ "replied_to_e1"
    end

    test "unregistered event isn't matched" do
      {_, %{step: step}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      event = EventSetup.Story.reply_sent(step, "invalid_reply", "e1")

      # Nothing happens...
      EventHelper.emit(event)
    end
  end

  describe "handling of completion events" do
    test "proceeds to the next step" do
      {_, %{entity_id: entity_id, step: step}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      event = EventSetup.Story.reply_sent(step, "reply_to_e3", "e3")

      EventHelper.emit(event)

      %{object: new_step} = StoryQuery.fetch_current_step(entity_id)

      refute new_step == step
      assert new_step.name == Step.get_next_step(step)
    end
  end
end
