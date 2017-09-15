defmodule Helix.Server.Websocket.Channel.Server.Requests.BootstrapTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias Helix.Test.Channel.Setup, as: ChannelSetup

  describe "bootstrap" do
    test "bootstraps remote server" do
      {socket, %{destination: destination}} = ChannelSetup.join_server()

      ref = push socket, "bootstrap", %{}
      assert_reply ref, :ok, response

      assert response.data.filesystem
      assert response.data.id == to_string(destination.server_id)
      assert response.data.logs
      assert response.data.nips
      assert response.data.processes
    end

    test "cant request bootstrap of own server" do
      {socket, _} = ChannelSetup.join_server([own_server: true])

      ref = push socket, "bootstrap", %{}
      assert_reply ref, :error, response

      assert response.data.message == "own_server_bootstrap"
    end
  end
end
