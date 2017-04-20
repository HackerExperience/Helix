defmodule Helix.Software.Service.Event.FileDownloadTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Software.Controller.File
  alias Helix.Software.Model.SoftwareType.FileDownload.ProcessConclusionEvent
  alias Helix.Software.Service.Event.FileDownload, as: Event

  alias Helix.Software.Factory

  describe "when process is complete" do
    test "copy target file to destination storage" do
      file = Factory.insert(:file)
      storage = Factory.insert(:storage, files: [])

      event = %ProcessConclusionEvent{
        target_file_id: file.file_id,
        server_id: Random.pk(),
        destination_storage_id: storage.storage_id
      }

      Event.complete(event)

      [new_file] = File.get_files_on_target_storage(storage)

      expected = Map.take(file, [:name, :file_size, :software_type])
      got = Map.take(new_file, [:name, :file_size, :software_type])

      assert expected == got
    end
  end
end
