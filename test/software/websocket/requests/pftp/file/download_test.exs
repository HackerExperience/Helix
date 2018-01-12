defmodule Helix.Software.Websocket.Requests.PFTP.File.DownloadTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Channel.Request.Macros

  alias Helix.Websocket.Requestable
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Software.Websocket.Requests.PFTP.File.Download,
    as: PFTPFileDownloadRequest

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "check_params/2" do
    test "requires a valid nip" do
      {socket, _} = ChannelSetup.join_server(own_server: true)

      p1 = %{
        "file_id" => "::f",
        "ip" => "Im not an ip",
        "network_id" => "::"
      }

      p2 = %{
        "file_id" => "Im not a file",
        "ip" => "1.2.3.4",
        "network_id" => "::"
      }

      p3 = %{
        "file_id" => "::f",
        "ip" => "1.2.3.4",
        "network_id" => "Im not an id"
      }

      valid = %{
        "file_id" => "::f",
        "ip" => "1.2.3.4",
        "network_id" => "::"
      }

      r1 = PFTPFileDownloadRequest.new(p1)
      r2 = PFTPFileDownloadRequest.new(p2)
      r3 = PFTPFileDownloadRequest.new(p3)

      assert {:error, %{message: e1}, _} = Requestable.check_params(r1, socket)
      assert {:error, %{message: e2}, _} = Requestable.check_params(r2, socket)
      assert {:error, %{message: e3}, _} = Requestable.check_params(r3, socket)

      # This is how you remind me of what I really am
      assert e1 == "bad_request"
      assert e2 == "bad_request"
      assert e3 == "bad_request"

      request = PFTPFileDownloadRequest.new(valid)
      assert {:ok, request} = Requestable.check_params(request, socket)

      assert request.params.file_id
      assert request.params.network_id
      assert request.params.storage_id
      assert request.params.target_id
    end
  end

  describe "check_permission/2" do
    test "henforces the request" do
      {socket, _} = ChannelSetup.join_server(own_server: true)
      {file, %{server: destination}} = SoftwareSetup.file()

      {:ok, [nip]} = CacheQuery.from_server_get_nips(destination)

      params = %{
        "file_id" => "::ffff",
        "network_id" => to_string(nip.network_id),
        "ip" => nip.ip
      }

      request = PFTPFileDownloadRequest.new(params)
      {:ok, request} = Requestable.check_params(request, socket)

      # Scenario: I've created a valid file in a valid endpoint...
      # Let's make it work.

      # First attempt.
      assert {:error, %{message: msg}, _} =
        Requestable.check_permissions(request, socket)

      # I've added the wrong file id.
      assert msg == "file_not_found"

      # Now let's try again with the correct file id.
      replace_param(request, :file_id, file.file_id)
      assert {:error, %{message: msg}, _} =
        Requestable.check_permissions(request, socket)

      # Raite, the file exists but it's not on the PFTP server.
      assert msg == "pftp_file_not_found"

      # Run the PFTP server and add the file to it.
      SoftwareSetup.PFTP.pftp(server_id: destination.server_id)
      SoftwareSetup.PFTP.file(
        server_id: destination.server_id,
        file_id: file.file_id
      )

      # Now it's valid!
      assert {:ok, request} = Requestable.check_permissions(request, socket)

      # Assigned correct fields to the meta
      assert request.meta.file == file
      assert request.meta.storage
      assert request.meta.gateway.server_id == socket.assigns.gateway.server_id
      assert request.meta.destination == destination

      # The destination storage is NOT the origin's file storage.
      refute request.meta.storage.storage_id == file.storage_id
    end
  end

  describe "handle_Request/2" do
    test "it uses values returned on previous step" do
      {socket, %{gateway: gateway}} = ChannelSetup.join_server(own_server: true)
      {file, %{server: destination}} = SoftwareSetup.file()

      # Setup the PFTP server and file
      SoftwareSetup.PFTP.pftp(server_id: destination.server_id)
      SoftwareSetup.PFTP.file(
        server_id: destination.server_id,
        file_id: file.file_id
      )

      {:ok, [nip]} = CacheQuery.from_server_get_nips(destination)

      params = %{
        "file_id" => to_string(file.file_id),
        "network_id" => to_string(nip.network_id),
        "ip" => nip.ip
      }

      request = PFTPFileDownloadRequest.new(params)
      {:ok, request} = Requestable.check_params(request, socket)
      {:ok, request} = Requestable.check_permissions(request, socket)
      assert {:ok, request} = Requestable.handle_request(request, socket)

      # The process has been created
      assert request.meta.process

      process = request.meta.process
      assert process.target_file_id == file.file_id
      assert process.gateway_id == gateway.server_id
      assert process.target_id == destination.server_id
      assert process.connection_id

      refute process.file_id
      refute process.target_connection_id

      TOPHelper.top_stop(gateway)
    end
  end
end
