defmodule Helix.Server.Event.MotherboardTest do

  use Helix.Test.Case.Integration

  alias Helix.Event.Publishable

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Event.Setup, as: EventSetup

  @socket_local ChannelSetup.mock_server_socket(access: :local)
  @socket_remote ChannelSetup.mock_server_socket(access: :remote)

  describe "MotherboardUpdatedEvent.generate_payload/2" do
    test "generates full hardware index on gateway (local)" do
      event = EventSetup.Server.motherboard_updated()

      assert {:ok, data} = Publishable.generate_payload(event, @socket_local)

      # Returns full data about the motherboard
      assert data.motherboard.motherboard_id
      assert data.motherboard.slots
      assert data.motherboard.network_connections
    end

    test "generates partial hardware index on endpoint (remote)" do
      event = EventSetup.Server.motherboard_updated()

      assert {:ok, data} = Publishable.generate_payload(event, @socket_remote)

      # Does not return information about the motherboard
      refute data.motherboard
    end
  end
end
