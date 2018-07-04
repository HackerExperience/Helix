defmodule Helix.Software.Websocket.Requests.File.UploadTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket.Requestable
  alias Helix.Software.Websocket.Requests.File.Upload, as: FileUploadRequest

  alias Helix.Test.Channel.Request.Helper, as: RequestHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @mock_socket ChannelSetup.mock_server_socket()

  describe "FileUploadRequest.check_params" do
    test "validates expected data" do
      file_id = SoftwareHelper.id()
      storage_id = SoftwareHelper.storage_id()

      params = %{
        "file_id" => to_string(file_id),
        "storage_id" => to_string(storage_id)
      }

      request = FileUploadRequest.new(params)

      assert {:ok, request} = Requestable.check_params(request, @mock_socket)

      # Casted file_id into the expected format
      assert request.params.file_id == file_id
      assert request.params.storage_id == storage_id
    end

    test "generates a storage_id if none was given" do
      {gateway, _} = ServerSetup.server()
      {destination, _} = ServerSetup.server()

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: gateway.server_id,
          destination_id: destination.server_id
        )

      params = %{
        "file_id" => to_string(SoftwareHelper.id())
      }

      request = FileUploadRequest.new(params)

      assert {:ok, request} = Requestable.check_params(request, socket)

      # Generated a storage_id if none was given
      assert request.params.storage_id
    end

    test "rejects upload on local connection" do
      local_socket = ChannelSetup.mock_server_socket(own_server: true)

      params = %{
        "file_id" => to_string(SoftwareHelper.id()),
        "storage_id" => to_string(SoftwareHelper.storage_id())
      }
      request = FileUploadRequest.new(params)

      assert {:error, data, _} = Requestable.check_params(request, local_socket)
      assert data.message == "upload_self"
    end
  end

  describe "FileUploadRequest.check_permissions" do
    test "accepts when everything is OK" do
      {gateway, _} = ServerSetup.server()
      {destination, _} = ServerSetup.server()

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: gateway.server_id,
          destination_id: destination.server_id
        )

      {file, _} = SoftwareSetup.file(server_id: gateway.server_id)
      storage = SoftwareHelper.get_storage(destination.server_id)

      params = %{
        file_id: file.file_id,
        storage_id: storage.storage_id
      }

      request = RequestHelper.mock_request(FileUploadRequest, params)
      assert {:ok, request} = Requestable.check_permissions(request, socket)

      assert request.meta.file == file
      assert request.meta.storage == storage
      assert request.meta.gateway == gateway
      assert request.meta.destination == destination
    end

    test "rejects if invalid file was passed" do
      params = %{
        file_id: SoftwareHelper.id(),
        storage_id: SoftwareHelper.storage_id()
      }

      request = RequestHelper.mock_request(FileUploadRequest, params)
      assert {:error, data, _} =
        Requestable.check_permissions(request, @mock_socket)
      assert data == %{message: "file_not_found"}
    end
  end

  describe "FileUploadRequest.handle_request" do
    test "starts the process" do
      {socket, %{gateway: gateway, destination: destination}} =
        ChannelSetup.join_server()

      file = SoftwareSetup.file!(server_id: gateway.server_id)
      storage = SoftwareHelper.get_storage(destination.server_id)

      params = %{
        file_id: file.file_id,
        storage_id: storage.storage_id
      }

      request = RequestHelper.mock_request(FileUploadRequest, params)
      {:ok, request} = Requestable.check_permissions(request, socket)
      assert {:ok, _request} = Requestable.handle_request(request, socket)

      TOPHelper.top_stop(gateway)
    end
  end
end
