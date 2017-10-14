defmodule Helix.Software.Websocket.Requests.PFTP.Server.DisableTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket.Requestable
  alias Helix.Software.Action.PublicFTP, as: PublicFTPAction
  alias Helix.Software.Websocket.Requests.PFTP.Server.Disable,
    as: PFTPServerDisableRequest

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "check_params/2" do
    test "does not allow pftp_server_disable on remote channel" do
      request = PFTPServerDisableRequest.new(%{})
      remote_socket = ChannelSetup.mock_server_socket()

      assert {:error, %{message: reason}} =
        Requestable.check_params(request, remote_socket)

      assert reason == "pftp_must_be_local"
    end
  end

  describe "check_permission/2" do
    test "henforces the request through PFTPHenforcer.can_disable_server" do
      # Note: this is not intended as an extensive test. For an extended
      # permission test, see `FileHenforcer.PublicFTPTest`.
      request = PFTPServerDisableRequest.new(%{})
      {socket, %{gateway: server}} = ChannelSetup.join_server()
      {pftp, _} = SoftwareSetup.pftp(server_id: server.server_id)

      assert {:ok, request} = Requestable.check_permissions(request, socket)
      assert request.meta.pftp == pftp

      # Now we'll disable pftp on that server, so the request should fail
      PublicFTPAction.disable_server(pftp)

      assert {:error, %{message: reason}} =
        Requestable.check_permissions(request, socket)

      assert reason == "pftp_already_disabled"
    end
  end

  describe "handle_request/2" do
    test "it uses the `pftp` returned on the `permissions` step" do
      request = PFTPServerDisableRequest.new(%{})
      {socket, %{gateway: server}} = ChannelSetup.join_server()
      SoftwareSetup.pftp(server_id: server.server_id)

      assert {:ok, request} = Requestable.check_permissions(request, socket)
      assert {:ok, _request} = Requestable.handle_request(request, socket)
    end
  end

  describe "reply/2" do
    test "response is empty when successful" do
      request = PFTPServerDisableRequest.new(%{})

      mock_socket = ChannelSetup.mock_server_socket(own_server: true)
      assert {:ok, response} = Requestable.reply(request, mock_socket)

      assert response == %{}
    end
  end
end
