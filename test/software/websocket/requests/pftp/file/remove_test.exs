defmodule Helix.Software.Websocket.Requests.PFTP.File.RemoveTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket.Requestable
  alias Helix.Software.Websocket.Requests.PFTP.File.Remove,
    as: PFTPFileRemoveRequest

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "check_params/2" do
    test "does not allow pftp_file_remove on remote channel" do
      request = PFTPFileRemoveRequest.new(%{})
      remote_socket = ChannelSetup.mock_server_socket()

      assert {:error, %{message: reason}, _} =
        Requestable.check_params(request, remote_socket)

      assert reason == "pftp_must_be_local"
    end

    test "requires a valid file_id param" do
      mock_socket = ChannelSetup.mock_server_socket(own_server: true)

      request1 = PFTPFileRemoveRequest.new(%{})
      request2 = PFTPFileRemoveRequest.new(%{"file_id" => "I'm not an id"})

      assert {:error, %{message: error1}, _} =
        Requestable.check_params(request1, mock_socket)
      assert {:error, %{message: error2}, _} =
        Requestable.check_params(request2, mock_socket)

      assert error1 == "bad_request"
      assert error2 == "bad_request"
    end
  end

  describe "check_permission/2" do
    test "henforces the request through PFTPHenforcer.can_remove_file" do
      # Note: this is not intended as an extensive test. For an extended
      # permission test, see `FileHenforcer.PublicFTPTest`.
      {socket, %{gateway: server}} = ChannelSetup.join_server(own_server: true)
      {file, _} = SoftwareSetup.file()

      params = %{
        "file_id" => to_string(file.file_id)
      }

      request = PFTPFileRemoveRequest.new(params)
      {:ok, request} = Requestable.check_params(request, socket)

      # Attempts to remove a file to my server
      assert {:error, %{message: reason}, _} =
        Requestable.check_permissions(request, socket)

      # But I have no PFTP server running :(
      assert reason == "pftp_not_found"

      # Ok, run the PFTP Server
      {pftp, _} = SoftwareSetup.PFTP.pftp(server_id: server.server_id)

      # Try again
      assert {:error, %{message: reason}, _} =
        Requestable.check_permissions(request, socket)

      # Opsie, I can't remove a file that isn't there ¯\_(ツ)_/¯
      assert reason == "pftp_file_not_found"

      # Here, let's add a file
      {pftp_file, _} = SoftwareSetup.PFTP.file(server_id: server.server_id)
      request = %{request| params: %{file_id: pftp_file.file_id}}

      # Worked like a PyCharm
      assert {:ok, request} = Requestable.check_permissions(request, socket)
      assert request.meta.pftp == pftp
      assert request.meta.pftp_file == pftp_file
    end
  end

  describe "handle_request/2" do
    test "it uses the `pftp` and `file` returned on the `permissions` step" do
      {socket, %{gateway: server}} = ChannelSetup.join_server(own_server: true)
      SoftwareSetup.PFTP.pftp(server_id: server.server_id)
      {pftp_file, _} = SoftwareSetup.PFTP.file(server_id: server.server_id)

      params = %{"file_id" => to_string(pftp_file.file_id)}

      request = PFTPFileRemoveRequest.new(params)
      {:ok, request} = Requestable.check_params(request, socket)
      {:ok, request} = Requestable.check_permissions(request, socket)

      assert {:ok, _request} = Requestable.handle_request(request, socket)
    end
  end

  describe "reply/2" do
    test "response is empty when successful" do
      request = PFTPFileRemoveRequest.new(%{})
      mock_socket = ChannelSetup.mock_server_socket(own_server: true)
      assert {:ok, response} = Requestable.reply(request, mock_socket)

      assert response == %{}
    end
  end
end
