defmodule Helix.Log.Event.LogTest do

  use Helix.Test.Case.Integration

  alias Helix.Event.Notificable

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Event.Setup, as: EventSetup

  @mocked_socket ChannelSetup.mock_server_socket()

  describe "LogCreatedEvent" do
    test "Notificable.generate_payload/2" do
      event = EventSetup.Log.created()

      # Generates the payload
      assert {:ok, data} = Notificable.generate_payload(event, @mocked_socket)

      # Returned payload and json-friendly
      assert data.log_id == to_string(event.log.log_id)
      assert data.message == event.log.message
      assert data.server_id == to_string(event.log.server_id)
      refute is_map(data.timestamp)

      # Returned event is correct
      assert "log_created" == Notificable.get_event_name(event)
    end

    test "Notificable.whom_to_notify/1" do
      event = EventSetup.Log.created()
      assert %{server: server_id} = Notificable.whom_to_notify(event)
      assert server_id == event.log.server_id
    end
  end

  describe "LogModifiedEvent" do
    test "Notificable.generate_payload/2" do
      event = EventSetup.Log.modified()

      # Generates the payload
      assert {:ok, data} = Notificable.generate_payload(event, @mocked_socket)

      # Returned payload is json-friendly
      assert data.log_id == to_string(event.log.log_id)
      assert data.message == event.log.message
      assert data.server_id == to_string(event.log.server_id)
      refute is_map(data.timestamp)

      # Returned event is correct
      assert "log_modified" == Notificable.get_event_name(event)
    end
  end

  describe "LogDeletedEvent" do
    test "Notificable.generate_payload/2" do
      event = EventSetup.Log.deleted()

      # Generates the payload
      assert {:ok, data} = Notificable.generate_payload(event, @mocked_socket)

      # Returned payload is json-friendly
      assert data.log_id == to_string(event.log.log_id)
      assert data.server_id == to_string(event.log.server_id)

      # Returned event is correct
      assert "log_deleted" == Notificable.get_event_name(event)
    end
  end
end
