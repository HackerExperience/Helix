defmodule Helix.Story.Event.ReplyTest do

  use Helix.Test.Case.Integration

  alias Helix.Event.Notificable

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Event.Setup, as: EventSetup

  describe "Notificable.whom_to_notify/1" do
    event = EventSetup.Story.reply_sent()

    notify = Notificable.whom_to_notify(event)

    assert notify == %{account: event.entity_id}
  end

  describe "Notificable.generate_payload/2" do
    socket = ChannelSetup.mock_account_socket()

    event = EventSetup.Story.reply_sent()

    assert {:ok, payload} = Notificable.generate_payload(event, socket)

    assert payload.event == "story_reply_sent"
    assert payload.data.step == to_string(event.step)
    assert payload.data.reply_to == event.reply_to
    assert payload.data.reply_id == event.reply_id
    refute is_map(payload.data.timestamp)
  end
end
