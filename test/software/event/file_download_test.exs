defmodule Helix.Software.Event.FileDownloadTest do

  use Helix.Test.IntegrationCase

  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Event.FileDownload, as: EventHandler
  alias Helix.Software.Model.SoftwareType.FileDownload.ProcessConclusionEvent

  alias Helix.Software.Factory

  describe "when process is complete" do
    test "copy target file to destination storage" do
      file = Factory.insert(:file)
      storage = Factory.insert(:storage, files: [])

      event = %ProcessConclusionEvent{
        to_server_id: Server.ID.generate(),
        from_server_id: Server.ID.generate(),
        from_file_id: file.file_id,
        to_storage_id: storage.storage_id,
        network_id: Network.ID.generate()
      }

      EventHandler.complete(event)

      [new_file] = FileInternal.get_files_on_target_storage(storage)

      expected = Map.take(file, [:name, :file_size, :software_type])
      got = Map.take(new_file, [:name, :file_size, :software_type])

      assert expected == got
    end
  end
end
