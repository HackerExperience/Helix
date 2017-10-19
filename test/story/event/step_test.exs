defmodule Helix.Story.Event.Step.ProceededTest do

  use Helix.Test.Case.Integration

  alias Helix.Event.Notificable

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Event.Setup, as: EventSetup

  describe "Notificable.whom_to_notify/1" do
    test "notifies only the player" do
      event = EventSetup.Story.step_proceeded()

      notify = Notificable.whom_to_notify(event)
      assert notify == %{account: event.entity_id}
    end
  end

  describe "Notificable.generate_payload/2" do
    test "generates the payload" do
      socket = ChannelSetup.mock_account_socket()

      event = EventSetup.Story.step_proceeded()

      assert {:ok, data} = Notificable.generate_payload(event, socket)

      assert data.previous_step == to_string(event.previous_step.name)
      assert data.next_step == to_string(event.next_step.name)

      assert "story_step_proceeded" == Notificable.get_event_name(event)
    end
  end
end
