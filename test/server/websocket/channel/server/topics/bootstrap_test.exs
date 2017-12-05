defmodule Helix.Server.Websocket.Channel.Server.Topics.BootstrapTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros

  alias Helix.Test.Channel.Setup, as: ChannelSetup

  describe "bootstrap" do
    test "bootstraps remote server" do
      {socket, _} = ChannelSetup.join_server()

      ref = push socket, "bootstrap", %{}
      assert_reply ref, :ok, response, timeout()

      assert response.data.main_storage
      assert response.data.storages
      assert response.data.logs
      assert response.data.nips
      assert response.data.processes

      # Specific to gateway
      refute Map.has_key?(response.data, :password)
      refute Map.has_key?(response.data, :name)
    end

    test "bootstrap local server" do
      {socket, _} = ChannelSetup.join_server([own_server: true])

      ref = push socket, "bootstrap", %{}
      assert_reply ref, :ok, response, timeout()

      assert response.data.main_storage
      assert response.data.storages
      assert response.data.logs
      assert response.data.nips
      assert response.data.processes

      # Specific to gateway
      assert response.data.password
      assert response.data.name
    end
  end
end
