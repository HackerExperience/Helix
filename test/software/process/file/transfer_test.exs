defmodule Helix.Software.Process.File.TransferTest do

  use Helix.Test.Case.Integration

  alias Helix.Process.Model.Processable
  alias Helix.Software.Model.Storage
  alias Helix.Software.Process.File.Transfer, as: FileTransferProcess

  alias Helix.Software.Event.File.Transfer.Aborted, as: FileTransferAbortedEvent

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Process.Helper, as: ProcessHelper
  alias Helix.Test.Process.Setup, as: ProcessSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @internet_id NetworkHelper.internet_id()

  describe "Process Kill" do
    test "aborted event is emitted (download)" do
      {process, _} = SoftwareSetup.Flow.file_transfer(:download)

      {_, [event]} = TOPHelper.soft_kill(process)

      assert %FileTransferAbortedEvent{} = event
      assert event.reason == :killed
      assert event.to_server_id == process.gateway_id
      assert event.from_server_id == process.target_id

      TOPHelper.top_stop(process.gateway_id)
    end

    test "aborted event is emitted (upload)" do
      {process, _} = SoftwareSetup.Flow.file_transfer(:upload)

      {_, [event]} = TOPHelper.soft_kill(process)

      assert %FileTransferAbortedEvent{} = event
      assert event.reason == :killed
      assert event.to_server_id == process.target_id
      assert event.from_server_id == process.gateway_id

      TOPHelper.top_stop(process.gateway_id)
    end
  end

  describe "Processable.after_read_hook/1" do
    test "converts correctly" do
      process = transfer_process()

      db_process = ProcessHelper.raw_get(process)

      serialized = Processable.after_read_hook(db_process.data)

      assert %Storage.ID{} = serialized.destination_storage_id
      assert is_atom(serialized.connection_type)
      assert is_atom(serialized.type)

      TOPHelper.top_stop()
    end

    defp transfer_process do
      type = Enum.random([:file_download, :file_upload])

      {process, _} = ProcessSetup.process(fake_server: true, type: type)
      process
    end
  end

  describe "Process.Resourceable" do
    test "download uses dlk" do
      {file, _} = SoftwareSetup.file()

      resources =
        FileTransferProcess.resources(
          %{type: :download, file: file, network_id: @internet_id}
        )

      # Uses DLK on gateway, ULK on remote
      assert resources.l_dynamic == [:dlk]
      assert resources.r_dynamic == [:ulk]

      # Objective depends on file size
      assert resources.objective.dlk[@internet_id] == file.file_size
      refute Map.has_key?(resources.objective, :ulk)

      # Uses RAM while paused and running
      assert resources.static.running.ram
      assert resources.static.paused.ram
    end

    test "upload uses ulk" do
      {file, _} = SoftwareSetup.file()

      resources =
        FileTransferProcess.resources(
          %{type: :upload, file: file, network_id: @internet_id}
        )

      # Uses ULK on gateway, DLK on remote
      assert resources.l_dynamic == [:ulk]
      assert resources.r_dynamic == [:dlk]

      # Objective depends on file size
      assert resources.objective.ulk[@internet_id] == file.file_size
      refute Map.has_key?(resources.objective, :dlk)

      # Uses RAM while paused and running
      assert resources.static.running.ram
      assert resources.static.paused.ram
    end
  end

  describe "Process.Executable" do
    # Tested at `FileTransferFlowTest`
  end
end
