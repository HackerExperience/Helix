defmodule Helix.Software.Action.Flow.File.TransferTest do

  use Helix.Test.Case.Integration

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Software.Action.Flow.File.Transfer, as: FileTransferFlow
  alias Helix.Software.Query.Storage, as: StorageQuery

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "transfer/4" do
    test "valid file download" do
      {gateway, _} = ServerSetup.server()
      {file, %{server_id: destination_id}} = SoftwareSetup.file()

      destination_storage = get_storage(gateway.server_id)

      network_info = %{
        gateway_id: gateway.server_id,
        destination_id: destination_id,
        network_id: NetworkHelper.internet(),
        bounces: [],
        tunnel: nil
      }

      {:ok, process} =
        FileTransferFlow.transfer(
          :download,
          file,
          destination_storage,
          network_info
        )

      # Generated process has the expected data
      assert process.process_type == "file_download"
      assert process.file_id == file.file_id
      assert process.process_data.type == :download
      assert process.process_data.connection_type == :ftp
      assert process.process_data.destination_storage_id ==
        destination_storage.storage_id

      # Generated connection is valid
      connection = TunnelQuery.fetch_connection(process.connection_id)
      assert connection.connection_type == :ftp

      TOPHelper.top_stop(gateway.server_id)
    end

    test "valid file upload" do
      {gateway, _} = ServerSetup.server()
      {file, %{server_id: destination_id}} = SoftwareSetup.file()

      destination_storage = get_storage(destination_id)

      network_info = %{
        gateway_id: gateway.server_id,
        destination_id: destination_id,
        network_id: NetworkHelper.internet(),
        bounces: [],
        tunnel: nil
      }

      {:ok, process} =
        FileTransferFlow.transfer(
          :upload,
          file,
          destination_storage,
          network_info
        )

      # Generated process has the expected data
      assert process.process_type == "file_upload"
      assert process.file_id == file.file_id
      assert process.process_data.type == :upload
      assert process.process_data.connection_type == :ftp
      assert process.process_data.destination_storage_id ==
        destination_storage.storage_id

      # Generated connection is valid
      connection = TunnelQuery.fetch_connection(process.connection_id)
      assert connection.connection_type == :ftp

      TOPHelper.top_stop(gateway.server_id)
    end

    test "valid file pftp_download" do
      {gateway, _} = ServerSetup.server()
      {file, %{server_id: destination_id}} = SoftwareSetup.file()

      destination_storage = get_storage(gateway.server_id)

      network_info = %{
        gateway_id: gateway.server_id,
        destination_id: destination_id,
        network_id: NetworkHelper.internet(),
        bounces: [],
        tunnel: nil
      }

      {:ok, process} =
        FileTransferFlow.transfer(
          :pftp_download,
          file,
          destination_storage,
          network_info
        )

      # Generated process has the expected data
      assert process.process_type == "file_download"
      assert process.file_id == file.file_id
      assert process.process_data.type == :download
      assert process.process_data.connection_type == :public_ftp
      assert process.process_data.destination_storage_id ==
        destination_storage.storage_id

      # Generated connection is valid
      connection = TunnelQuery.fetch_connection(process.connection_id)
      assert connection.connection_type == :public_ftp

      TOPHelper.top_stop(gateway.server_id)
    end

    @tag :pending
    test "rejects repeated transfers"

    defp get_storage(server_id) do
      server_id
      |> CacheQuery.from_server_get_storages()
      |> elem(1)
      |> List.first()
      |> StorageQuery.fetch()
    end
  end
end
