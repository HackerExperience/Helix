defmodule Helix.Story.Action.Flow.StoryTest do

  use Helix.Test.Case.Integration

  import ExUnit.CaptureLog

  alias Helix.Story.Action.Flow.Story, as: StoryFlow
  alias Helix.Story.Query.Story, as: StoryQuery

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Story.Helper, as: StoryHelper
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "send_reply/3" do
    test "sends the reply when everything is valid" do
      {_, %{entity_id: entity_id}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      [%{entry: entry, object: step}] = StoryQuery.get_steps(entity_id)
      reply_id = StoryHelper.get_allowed_reply(entry)

      # `reply_to_e1` emits a log once handled, so we are capturing it here to
      # avoid the Log output from polluting the test results.
      capture_log(fn ->
        assert :ok = StoryFlow.send_reply(entity_id, step.contact, reply_id)
      end)
    end

    test "fails when step is not found (wrong contact)" do
      {_, %{entity_id: entity_id}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      [%{entry: entry}] = StoryQuery.get_steps(entity_id)
      reply_id = StoryHelper.get_allowed_reply(entry)

      # Correct entity, correct reply_id, but wrong contact.
      assert {:error, :bad_step} ==
        StoryFlow.send_reply(entity_id, StoryHelper.contact_id(), reply_id)
    end

    test "fails when reply does not exist" do
      {_, %{step: step, entity_id: entity_id}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      reply_id = "locked_reply_to_e1"

      assert {:error, reason} =
        StoryFlow.send_reply(entity_id, step.contact, reply_id)
      assert reason == {:reply, :not_found}
    end

    test "fails when player is not in a mission" do
      assert {:error, :bad_step} ==
        StoryFlow.send_reply(
          EntityHelper.id(),
          StoryHelper.contact_id(),
          "reply_id"
        )
    end
  end
end
