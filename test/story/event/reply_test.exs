defmodule Helix.Story.Event.ReplyTest do

  use Helix.Test.Case.Integration

  alias Helix.Event.Notificable

  alias Helix.Test.Channel.Helper, as: ChannelHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "Notificable.whom_to_notify/1" do
    {step, _} = StorySetup.step()

    event = EventSetup.story_reply_sent(step, "reply_id", "reply_to")

    notification_list = Notificable.whom_to_notify(event)
    assert notification_list == [ChannelHelper.to_topic(step.entity_id)]
  end

  describe "Notificable.generate_payload/2" do
    {step, _} = StorySetup.step()
    socket = ChannelSetup.mock_account_socket()

    reply_to = "all my exes"
    reply_id = "live in texas"
    event = EventSetup.story_reply_sent(step, reply_id, reply_to)

    assert {:ok, payload} = Notificable.generate_payload(event, socket)

    assert payload.event == "story_reply_sent"
    assert payload.data.step == to_string(step.name)
    assert payload.data.reply_to == reply_to
    assert payload.data.reply_id == reply_id
    refute is_map(payload.data.timestamp)
  end
end
