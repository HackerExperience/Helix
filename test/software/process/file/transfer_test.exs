defmodule Helix.Software.Process.File.TransferTest do

  use Helix.Test.Case.Integration

  alias Helix.Process.Model.Process.ProcessType
  alias Helix.Software.Model.Storage

  alias Helix.Software.Event.File.Transfer.Aborted, as: FileTransferAbortedEvent

  alias Helix.Test.Software.Setup.Flow, as: SoftwareFlowSetup
  alias Helix.Test.Process.Setup, as: ProcessSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Process.Helper, as: ProcessHelper

  describe "Process Kill" do
    test "aborted event is emitted (download)" do
      {process, _} = SoftwareFlowSetup.file_transfer(:download)

      {_, [event]} = TOPHelper.soft_kill(process)

      assert %FileTransferAbortedEvent{} = event
      assert event.reason == :killed
      assert event.to_server_id == process.gateway_id
      assert event.from_server_id == process.target_server_id

      TOPHelper.top_stop(process.gateway_id)
    end

    test "aborted event is emitted (upload)" do
      {process, _} = SoftwareFlowSetup.file_transfer(:upload)

      {_, [event]} = TOPHelper.soft_kill(process)

      assert %FileTransferAbortedEvent{} = event
      assert event.reason == :killed
      assert event.to_server_id == process.target_server_id
      assert event.from_server_id == process.gateway_id

      TOPHelper.top_stop(process.gateway_id)
    end
  end

  describe "ProcessType.after_read_hook/1" do
    test "converts correctly" do
      process = transfer_process()

      db_process = ProcessHelper.raw_get(process)

      serialized = ProcessType.after_read_hook(db_process.process_data)

      assert %Storage.ID{} = serialized.destination_storage_id
      assert is_atom(serialized.connection_type)
      assert is_atom(serialized.type)
    end
  end

  defp transfer_process do
    type = Enum.random([:file_download, :file_upload])

    {process, _} = ProcessSetup.process(fake_server: true, type: type)
    process
  end

  # TODO: Waiting for #269 being merged, which changed ProcessViewHelper
  # describe "ProcessView.render/4 for download" do
  #   test "full process returns storage_id"
  # end
end
