defmodule Helix.Software.Action.Flow.File.TransferTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Software.Action.Flow.File.Transfer, as: FileTransferFlow

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @relay nil

  describe "transfer/4" do
    test "valid file download" do
      {gateway, _} = ServerSetup.server()
      {destination, _} = ServerSetup.server()
      {file, _} = SoftwareSetup.file(server_id: destination.server_id)

      destination_storage = SoftwareHelper.get_storage(gateway.server_id)

      net = NetworkHelper.net()

      {:ok, process} =
        FileTransferFlow.download(
          gateway, destination, file, destination_storage, net, @relay
        )

      # Generated process has the expected data
      assert process.type == :file_download
      assert process.tgt_file_id == file.file_id
      assert process.data.type == :download
      assert process.data.connection_type == :ftp
      assert process.data.destination_storage_id ==
        destination_storage.storage_id
      refute process.src_file_id
      refute process.tgt_connection_id

      # Generated connection is valid
      connection = TunnelQuery.fetch_connection(process.src_connection_id)
      assert connection.connection_type == :ftp

      # Transferring again returns the same process (does not create a new one)
      {:ok, process2} =
        FileTransferFlow.download(
          gateway, destination, file, destination_storage, net, @relay
        )

      assert process2.process_id == process.process_id

      TOPHelper.top_stop(gateway)
    end

    test "valid file upload" do
      {gateway, _} = ServerSetup.server()
      {destination, _} = ServerSetup.server()
      {file, _} = SoftwareSetup.file(server_id: destination.server_id)

      destination_storage = SoftwareHelper.get_storage(destination)

      net = NetworkHelper.net()

      {:ok, process} =
        FileTransferFlow.upload(
          gateway, destination, file, destination_storage, net, @relay
        )

      # Generated process has the expected data
      assert process.type == :file_upload
      assert process.tgt_file_id == file.file_id
      assert process.data.type == :upload
      assert process.data.connection_type == :ftp
      assert process.data.destination_storage_id ==
        destination_storage.storage_id
      refute process.src_file_id
      refute process.tgt_connection_id

      # Generated connection is valid
      connection = TunnelQuery.fetch_connection(process.src_connection_id)
      assert connection.connection_type == :ftp

      # Transferring again returns the same process (does not create a new one)
      {:ok, process2} =
        FileTransferFlow.upload(
          gateway, destination, file, destination_storage, net, @relay
        )

      assert process2.process_id == process.process_id

      TOPHelper.top_stop(gateway)
    end

    test "valid file pftp_download" do
      {gateway, _} = ServerSetup.server()
      {destination, _} = ServerSetup.server()
      {file, _} = SoftwareSetup.file(server_id: destination.server_id)

      destination_storage = SoftwareHelper.get_storage(gateway)

      net = NetworkHelper.net()

      {:ok, process} =
        FileTransferFlow.pftp_download(
          gateway, destination, file, destination_storage, net, @relay
        )

      # Generated process has the expected data
      assert process.type == :file_download
      assert process.tgt_file_id == file.file_id
      assert process.data.type == :download
      assert process.data.connection_type == :public_ftp
      assert process.data.destination_storage_id ==
        destination_storage.storage_id

      refute process.src_file_id
      refute process.tgt_connection_id

      # Generated connection is valid; tunnel was created
      connection = TunnelQuery.fetch_connection(process.src_connection_id)
      assert connection.connection_type == :public_ftp

      # Transferring again returns the same process (does not create a new one)
      {:ok, process2} =
        FileTransferFlow.pftp_download(
          gateway, destination, file, destination_storage, net, @relay
        )

      assert process2.process_id == process.process_id

      TOPHelper.top_stop(gateway.server_id)
    end
  end
end
