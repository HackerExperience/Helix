defmodule Helix.Story.Event.Step.ProceededTest do

  use Helix.Test.Case.Integration

  alias Helix.Event.Publishable

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Event.Setup, as: EventSetup

  describe "Publishable.whom_to_publish/1" do
    test "publishes only to the player" do
      event = EventSetup.Story.step_proceeded()

      publish = Publishable.whom_to_publish(event)
      assert publish == %{account: event.entity_id}
    end
  end

  describe "Publishable.generate_payload/2" do
    test "generates the payload" do
      socket = ChannelSetup.mock_account_socket()

      event = EventSetup.Story.step_proceeded()

      assert {:ok, data} = Publishable.generate_payload(event, socket)

      assert data.previous_step == to_string(event.previous_step.name)
      assert data.next_step == to_string(event.next_step.name)

      assert "story_step_proceeded" == Publishable.get_event_name(event)
    end
  end
end
