defmodule HELL.LogflixTest do

  use Helix.Test.Case.Integration
  use Helix.Logger

  import Phoenix.ChannelTest

  alias HELL.Logflix
  alias Helix.Websocket.Request.Relay, as: RequestRelay

  alias Helix.Test.Channel.Setup, as: ChannelSetup

  describe "Logflix" do
    test "receives log publication" do
      {socket, _} =  ChannelSetup.create_socket()

      # Join & subscribe to Logflix
      subscribe_and_join(socket, Logflix, "logflix")

      # Create fake request/socket data
      request_id = "abc123"
      request = %{"request_id" => request_id}
      fake_socket = ChannelSetup.mock_account_socket()

      # Simulate a RequestRelay
      relay = RequestRelay.new(request, fake_socket)

      # Simulate the logging of an event
      log :logger_test, :log_id,
        data: %{foo: %{bar: :baz}},
        relay: relay

      # Receive the "new_log" message
      assert_push "event", log

      # Log data is correct
      assert log.data.type == "logger_test"
      assert log.data.meta.id == "log_id"
      assert log.data.meta.data.foo.bar == "baz"
      assert log.data.timestamp

      # It correlates the request_id and the account_id (from relay)
      assert log.data.meta.request_id == request_id
      assert log.data.meta.account_id ==
        fake_socket.assigns.account_id |> to_string()
    end
  end
end
