defmodule Helix.Story.Event.EmailTest do

  use Helix.Test.Case.Integration

  alias Helix.Event.Publishable

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Event.Setup, as: EventSetup

  describe "Publishable.whom_to_publish/1" do
    test "publishes only to the player" do
      event = EventSetup.Story.email_sent()

      publish = Publishable.whom_to_publish(event)
      assert publish == %{account: event.entity_id}
    end
  end

  describe "Publishable.generate_payload/2" do
    test "generates the payload" do
      socket = ChannelSetup.mock_account_socket()

      event = EventSetup.Story.email_sent()

      assert {:ok, data} = Publishable.generate_payload(event, socket)

      assert data.step == to_string(event.step.name)
      assert data.email_id == event.email.id
      assert is_binary(data.contact_id)
      assert data.meta
      assert data.replies
      assert is_float(data.timestamp)

      assert "story_email_sent" == Publishable.get_event_name(event)
    end
  end
end
