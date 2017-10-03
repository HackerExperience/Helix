defmodule Helix.Story.Event.EmailTest do

  use Helix.Test.Case.Integration

  alias Helix.Event.Notificable

  alias Helix.Test.Channel.Helper, as: ChannelHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Event.Setup, as: EventSetup

  describe "Notificable.whom_to_notify/1" do
    test "notifies only the player" do
      event = EventSetup.Story.email_sent()

      notification_list = Notificable.whom_to_notify(event)
      assert notification_list == [ChannelHelper.to_topic(event.entity_id)]
    end
  end

  describe "Notificable.generate_payload/2" do
    socket = ChannelSetup.mock_account_socket()

    event = EventSetup.Story.email_sent()

    assert {:ok, payload} = Notificable.generate_payload(event, socket)

    assert payload.event == "story_email_sent"
    assert payload.data.step == to_string(event.step)
    assert payload.data.email_id == event.email_id
    refute is_map(payload.data.timestamp)
  end
end
