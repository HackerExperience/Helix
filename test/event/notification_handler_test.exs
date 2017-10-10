defmodule Helix.Event.NotificationHandlerTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Case.ID
  import Helix.Test.Event.Macros

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Event.Setup, as: EventSetup

  @moduletag :driver

  # Behold, adventurer! The tests below are meant to ensure
  # `notification_handler/1` works correctly under the hood, as well as Phoenix
  # behavior of intercepting and filtering out an event.
  # It is not mean to extensively test all events. For this, refer to the
  # specific event's test file.
  # As such, we use `ProcessCreatedEvent` here merely as an example. Peace.
  describe "notification_handler/1" do
    test "notifies gateway that a process was created (single-server)" do
      {_socket, %{gateway: gateway}} =
        ChannelSetup.join_server([own_server: true])

      event =
        EventSetup.process_created(
          :single_server,
          [gateway_id: gateway.server_id])

      # Process happens on the same server
      assert event.gateway_id == event.target_id

      EventHelper.emit(event)

      # Broadcast is before inspecting the event with `handle_out`, so this
      # isn't the final output to the client
      assert_broadcast "event", internal_broadcast
      assert_event internal_broadcast, event

      # Now that's what the client actually receives.
      assert_push "event", notification
      assert notification.event == "process_created"

      # Make sure all we need is on the process return
      assert_id notification.data.process_id, event.process.process_id
      assert notification.data.type == event.process.process_type
      assert_id notification.data.file_id, event.process.file_id
      assert_id notification.data.connection_id, event.process.connection_id
      assert_id notification.data.network_id, event.process.network_id
      assert notification.data.target_ip
      assert notification.data.source_ip

      # Event id was generated
      assert notification.event_id
      assert is_binary(notification.event_id)
    end

    test "multi-server" do
      {socket, %{gateway: gateway, destination: destination}} =
        ChannelSetup.join_server()

      # Filter out the usual `LogCreatedEvent` after remote server join
      assert_broadcast "event", _

      gateway_entity_id = socket.assigns.gateway.entity_id
      destination_entity_id = socket.assigns.destination.entity_id

      event =
        EventSetup.process_created(
          gateway.server_id,
          destination.server_id,
          gateway_entity_id,
          destination_entity_id)

      # Process happens on two different servers
      refute event.gateway_id == event.target_id

      EventHelper.emit(event)

      # Broadcast is before inspecting the event with `handle_out`, so this
      # isn't the final output to the client
      assert_broadcast "event", internal_broadcast
      assert_event internal_broadcast, event

      # Now that's what the client actually receives.
      assert_push "event", notification
      assert notification.event == "process_created"

      # Make sure all we need is on the process return
      assert_id notification.data.process_id, event.process.process_id
      assert notification.data.type == event.process.process_type
      assert_id notification.data.file_id, event.process.file_id
      assert_id notification.data.connection_id, event.process.connection_id
      assert_id notification.data.network_id, event.process.network_id
      assert notification.data.target_ip
      assert notification.data.source_ip

      # Event id was generated
      assert notification.event_id
      assert is_binary(notification.event_id)
    end
  end
end
