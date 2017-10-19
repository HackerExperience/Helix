defmodule Helix.Server.Websocket.Channel.Server.Requests.BootstrapTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias Helix.Test.Channel.Setup, as: ChannelSetup

  describe "bootstrap" do
    test "bootstraps remote server" do
      {socket, _} = ChannelSetup.join_server()

      ref = push socket, "bootstrap", %{}
      assert_reply ref, :ok, response

      assert response.data.filesystem
      assert response.data.logs
      assert response.data.nips
      assert response.data.processes

      # Specific to gateway
      refute Map.has_key?(response.data, :password)
      refute Map.has_key?(response.data, :name)
    end

    test "cant request bootstrap of own server" do
      {socket, _} = ChannelSetup.join_server([own_server: true])

      ref = push socket, "bootstrap", %{}
      assert_reply ref, :ok, response

      assert response.data.filesystem
      assert response.data.logs
      assert response.data.nips
      assert response.data.processes

      # Specific to gateway
      assert response.data.password
      assert response.data.name
    end
  end
end
