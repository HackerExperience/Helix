defmodule Helix.Software.Websocket.Requests.PFTP.Server.EnableTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket.Requestable
  alias Helix.Software.Websocket.Requests.PFTP.Server.Enable,
    as: PFTPServerEnableRequest

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "check_params/2" do
    test "does not allow pftp_server_enable on remote channel" do
      request = PFTPServerEnableRequest.new(%{})
      remote_socket = ChannelSetup.mock_server_socket()

      assert {:error, %{message: reason}} =
        Requestable.check_params(request, remote_socket)

      assert reason == "pftp_must_be_local"
    end
  end

  describe "check_permission/2" do
    test "henforces the request through PFTPHenforcer.can_enable_server" do
      # Note: this is not intended as an extensive test. For an extended
      # permission test, see `FileHenforcer.PublicFTPTest`.
      request = PFTPServerEnableRequest.new(%{})
      {socket, _} = ChannelSetup.join_server(own_server: true)

      assert {:ok, request} = Requestable.check_permissions(request, socket)
      assert request.meta.server.server_id == socket.assigns.gateway.server_id

      # Now we'll enable pftp on that server, so the request should fail
      SoftwareSetup.pftp(server_id: socket.assigns.gateway.server_id)

      assert {:error, %{message: reason}} =
        Requestable.check_permissions(request, socket)

      assert reason == "pftp_already_enabled"
    end
  end

  describe "handle_request/2" do
    test "it uses the `server` returned on the `permissions` step" do
      request = PFTPServerEnableRequest.new(%{})
      {socket, _} = ChannelSetup.join_server(own_server: true)

      assert {:ok, request} = Requestable.check_permissions(request, socket)
      assert {:ok, _request} = Requestable.handle_request(request, socket)
    end
  end

  describe "reply/2" do
    test "response is empty when successful" do
      request = PFTPServerEnableRequest.new(%{})

      mock_socket = ChannelSetup.mock_server_socket(own_server: true)
      assert {:ok, response} = Requestable.reply(request, mock_socket)

      assert response == %{}
    end
  end
end
