defmodule Helix.Software.Action.Flow.File.TransferTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Software.Action.Flow.File.Transfer, as: FileTransferFlow

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "transfer/4" do
    test "valid file download" do
      {gateway, _} = ServerSetup.server()
      {file, %{server_id: destination_id}} = SoftwareSetup.file()

      destination_storage = SoftwareHelper.get_storage(gateway.server_id)

      network_info = %{
        gateway_id: gateway.server_id,
        destination_id: destination_id,
        network_id: NetworkHelper.internet(),
        bounces: []
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

      # Transferring again returns the same process (does not create a new one)
      {:ok, process2} =
        FileTransferFlow.transfer(
          :download,
          file,
          destination_storage,
          network_info
        )

      assert process2.process_id == process.process_id

      TOPHelper.top_stop(gateway.server_id)
    end

    test "valid file upload" do
      {gateway, _} = ServerSetup.server()
      {file, %{server_id: destination_id}} = SoftwareSetup.file()

      destination_storage = SoftwareHelper.get_storage(destination_id)

      network_info = %{
        gateway_id: gateway.server_id,
        destination_id: destination_id,
        network_id: NetworkHelper.internet(),
        bounces: []
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

      # Transferring again returns the same process (does not create a new one)
      {:ok, process2} =
        FileTransferFlow.transfer(
          :upload,
          file,
          destination_storage,
          network_info
        )

      assert process2.process_id == process.process_id

      TOPHelper.top_stop(gateway.server_id)
    end

    test "valid file pftp_download" do
      {gateway, _} = ServerSetup.server()
      {file, %{server_id: destination_id}} = SoftwareSetup.file()

      destination_storage = SoftwareHelper.get_storage(gateway.server_id)

      network_info = %{
        gateway_id: gateway.server_id,
        destination_id: destination_id,
        network_id: NetworkHelper.internet(),
        bounces: []
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

      # Generated connection is valid; tunnel was created
      connection = TunnelQuery.fetch_connection(process.connection_id)
      assert connection.connection_type == :public_ftp

      # Transferring again returns the same process (does not create a new one)
      {:ok, process2} =
        FileTransferFlow.transfer(
          :pftp_download,
          file,
          destination_storage,
          network_info
        )

      assert process2.process_id == process.process_id

      TOPHelper.top_stop(gateway.server_id)
    end

    @tag :pending
    test "rejects repeated transfers"
  end
end
