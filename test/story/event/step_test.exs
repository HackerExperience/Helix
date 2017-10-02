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
    socket = ChannelSetup.mock_account_socket()

    event = EventSetup.Story.step_proceeded()

    assert {:ok, payload} = Notificable.generate_payload(event, socket)

    assert payload.event == "story_step_proceeded"
    assert payload.data.previous_step == event.previous_step
    assert payload.data.next_step == event.next_step
  end
end
