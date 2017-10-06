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
      assert {:ok, return} = Notificable.generate_payload(event, @mocked_socket)

      # Returned event is correct and json-friendly
      assert return.event == "log_created"
      assert return.data.log_id == to_string(event.log.log_id)
      assert return.data.message == event.log.message
      assert return.data.server_id == to_string(event.log.server_id)
      refute is_map(return.data.timestamp)
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
      assert {:ok, return} = Notificable.generate_payload(event, @mocked_socket)

      # Returned event is correct and json-friendly
      assert return.event == "log_modified"
      assert return.data.log_id == to_string(event.log.log_id)
      assert return.data.message == event.log.message
      assert return.data.server_id == to_string(event.log.server_id)
      refute is_map(return.data.timestamp)
    end
  end

  describe "LogDeletedEvent" do
    test "Notificable.generate_payload/2" do
      event = EventSetup.Log.deleted()

      # Generates the payload
      assert {:ok, return} = Notificable.generate_payload(event, @mocked_socket)

      # Returned event is correct and json-friendly
      assert return.event == "log_deleted"
      assert return.data.log_id == to_string(event.log.log_id)
      assert return.data.server_id == to_string(event.log.server_id)
    end
  end
end
