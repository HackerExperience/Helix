defmodule Helix.Websocket.Requests.ProxyTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros

  alias Helix.Test.Channel.Setup, as: ChannelSetup

  # Note: we are using `client.setup` simply as an example of a request that
  # implements a RequestProxy behaviour.
  describe "client.setup" do
    test "dispatches to the underlying client" do
      opts = [socket_opts: [client: :web1]]
      {socket, _} = ChannelSetup.join_account(opts)

      # Sending request to `web1`, which implements `client.setup`
      assert socket.assigns.client == :web1

      params =
        %{
          "pages" => ["welcome"],
          "request_id" => "id"
        }

      ref = push socket, "client.setup", params

      # Received a valid (:ok) response
      assert_reply ref, :ok, response, timeout()

      assert response.meta.request_id == params["request_id"]
    end

    test "rejects if underlying client does not implement request" do
      opts = [socket_opts: [client: :mobile1]]
      {socket, _} = ChannelSetup.join_account(opts)

      # Mobile1 does not implement `client.setup`
      assert socket.assigns.client == :mobile1

      ref = push socket, "client.setup", %{}
      assert_reply ref, :error, response, timeout()

      # Nope
      assert response.data.message == "request_not_implemented_for_client"
    end
  end
end
