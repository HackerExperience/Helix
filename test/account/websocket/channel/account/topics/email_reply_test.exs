defmodule Helix.Account.Websocket.Channel.Account.Topics.EmailReplyTest do

  use Helix.Test.Case.Integration

  import ExUnit.CaptureLog
  import Phoenix.ChannelTest
  import Helix.Test.Macros

  alias Helix.Story.Query.Story, as: StoryQuery

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Story.Helper, as: StoryHelper
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "email.reply" do
    test "replies an email when correct data is given" do
      {socket, %{entity_id: entity_id}} = ChannelSetup.join_account()

      StorySetup.story_step(
        entity_id: entity_id,
        name: :fake_steps@test_msg,
        meta: %{}
      )

      %{entry: entry} = StoryQuery.fetch_current_step(entity_id)
      reply_id = StoryHelper.get_allowed_reply(entry)

      params = %{"reply_id" => reply_id}

      ref = push socket, "email.reply", params

      # Wrapped into a `capture_log` because the reply will cause a log to be
      # outputted. Capturing it here so it doesn't bloat the test results.
      capture_log(fn ->
        assert_reply ref, :ok, response, timeout()
        assert response.data == %{}
      end)
    end

    test "fails if reply is invalid" do
      {socket, %{entity_id: entity_id}} = ChannelSetup.join_account()

      StorySetup.story_step(
        entity_id: entity_id,
        name: :fake_steps@test_msg,
        meta: %{}
      )

      params = %{"reply_id" => "invalid_reply"}

      ref = push socket, "email.reply", params

      assert_reply ref, :error, response, timeout(:fast)
      assert response.data.message == "reply_not_found"
    end

    test "fails if player is not currently in a mission" do
      {socket, %{entity_id: entity_id}} = ChannelSetup.join_account()

      # Remove any existing step
      StoryHelper.remove_existing_step(entity_id)

      ref = push socket, "email.reply", %{"reply_id" => "lolzor"}

      assert_reply ref, :error, response, timeout(:fast)
      assert response.data.message == "not_in_step"
    end
  end
end
