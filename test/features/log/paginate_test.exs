defmodule Helix.Test.Features.Log.Paginate do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Log.Setup, as: LogSetup

  @moduletag :feature

  describe "log recover" do
    test "Fetches logs older than `log_id`" do
      {socket, %{server: gateway}} = ChannelSetup.create_socket()

      # Connect to gateway channel
      {socket, _} =
        ChannelSetup.join_server(
          gateway_id: gateway.server_id,
          own_server: true,
          socket: socket,
          skip_logs: true
        )

      _log1 =
        LogSetup.log!(
          log_id: "e3ac:6eef:c924:a009:3f17:1abd:d5d8:5809",
          server_id: gateway.server_id
        )

      log2 =
        LogSetup.log!(
          log_id: "e3ac:6eef:c924:a009:3f17:279f:9983:8709",
          server_id: gateway.server_id
        )

      log3 =
        LogSetup.log!(
          log_id: "e3ac:6eef:c924:a009:3f17:3243:a825:4009",
          server_id: gateway.server_id
        )

      # We'll use `log2` as starting point, so `log1` and `log2` should not be
      # fetched.

      params = %{"log_id" => to_string(log2.log_id)}

      ref = push socket, "log.paginate", params
      assert_reply ref, :ok, response, timeout(:slow)

      logs = response.data

      # Only one log was returned...
      assert length(logs) == 1

      # And it is `log3`
      assert List.first(logs).log_id == to_string(log3.log_id)
    end
  end
end
