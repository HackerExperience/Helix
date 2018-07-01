defmodule Helix.Core.Listener.Event.Handler.ListenerTest do

  use Helix.Test.Case.Integration

  import Helix.Core.Listener

  alias Helix.Event
  alias Helix.Software.Event.File.Downloaded, as: FileDownloadedEvent
  alias Helix.Software.Event.File.Uploaded, as: FileUploadedEvent

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper

  def callback(%FileDownloadedEvent{}) do
    send(self(), :hello_joe)

    {:ok, []}
  end

  def callmeta(%FileDownloadedEvent{}, meta) do
    send(self(), {:hello_meta, meta})

    {:ok, []}
  end

  describe "Event handling" do
    test "objects being listened will have their callback called" do
      file_downloaded = EventSetup.Software.file_downloaded()

      listen file_downloaded.source_file_id, FileDownloadedEvent, :callback,
        owner_id: file_downloaded.entity_id,
        subscriber: :teste_daora

      Event.emit(file_downloaded)

      assert_receive :hello_joe
    end

    test "won't receive anything if event did not match" do
      file_downloaded = EventSetup.Software.file_downloaded()

      # Listening to the same event but on a different object
      listen SoftwareHelper.id(), FileDownloadedEvent, :callback,
        owner_id: file_downloaded.entity_id,
        subscriber: :teste_daora

      # Listening on the same object but on a different event
      listen file_downloaded.source_file_id, FileUploadedEvent, :callback,
        owner_id: file_downloaded.entity_id,
        subscriber: :teste_daora

      Event.emit(file_downloaded)

      refute_receive :hello_joe
    end

    test "multiple entries get called multiple times; meta works too" do
      file_downloaded = EventSetup.Software.file_downloaded()

      listen file_downloaded.source_file_id, FileDownloadedEvent, :callback,
        owner_id: file_downloaded.entity_id,
        subscriber: :teste_daora

      listen file_downloaded.source_file_id, FileDownloadedEvent, :callback,
        owner_id: file_downloaded.entity_id,
        subscriber: :teste_daora_2

      listen file_downloaded.source_file_id, FileDownloadedEvent, :callmeta,
        meta: %{entity_id: file_downloaded.entity_id},
        owner_id: file_downloaded.entity_id,
        subscriber: :teste_daora_3

      Event.emit(file_downloaded)

      assert_receive :hello_joe
      assert_receive :hello_joe
      assert_receive {:hello_meta, meta}

      assert meta.entity_id == to_string(file_downloaded.entity_id)
    end
  end
end
