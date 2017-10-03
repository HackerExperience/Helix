defmodule Helix.Story.Public.StoryTest do

  use Helix.Test.Case.Integration

  import ExUnit.CaptureLog

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Query.Story, as: StoryQuery
  alias Helix.Story.Public.Story, as: StoryPublic

  alias Helix.Test.Story.Helper, as: StoryHelper
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "send_reply/2" do

    test "sends the reply when everything is valid" do
      {_, %{entity_id: entity_id}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      %{entry: entry} = StoryQuery.fetch_current_step(entity_id)
      reply_id = StoryHelper.get_allowed_reply(entry)

      # `reply_to_e1` emits a log once handled, so we are capturing it here to
      # avoid the Log output from polluting the test results.
      capture_log(fn ->
        assert :ok = StoryPublic.send_reply(entity_id, reply_id)
      end)
    end

    test "fails when reply does not exist" do
      {_, %{entity_id: entity_id}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      reply_id = "locked_reply_to_e1"

      assert {:error, reason} = StoryPublic.send_reply(entity_id, reply_id)
      assert reason == %{message: "reply_not_found"}
    end

    test "fails when player is not in a mission" do
      assert {:error, reason} =
        StoryPublic.send_reply(Entity.ID.generate(), "reply_id")
      assert reason == %{message: "not_in_step"}
    end
  end
end
