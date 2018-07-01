defmodule Helix.Core.ListenerTest do

  use Helix.Test.Case.Integration

  import Helix.Core.Listener

  alias Helix.Core.Listener.Query.Listener, as: ListenerQuery

  alias Helix.Software.Event.File.Downloaded, as: FileDownloadedEvent

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Software.Helper, as: SoftwareHelper

  describe "listen/4" do
    test "persists entry on DB" do
      file_id = SoftwareHelper.id()
      entity_id = EntityHelper.id()

      # Listen for `FileDownloadedEvent` on `file_id`
      listen file_id, FileDownloadedEvent, :callback,
        owner_id: entity_id,
        subscriber: :alo_som_testando_123

      # Ensure the entry was created
      assert [listener] =
        ListenerQuery.get_listeners(file_id, FileDownloadedEvent)

      assert listener.method == "callback"
      assert listener.module == to_string(__MODULE__)
      assert listener.meta == nil
    end
  end

  describe "unlisten/4" do
    test "removes entry from DB" do
      file_id = SoftwareHelper.id()
      entity_id = EntityHelper.id()

      # Listen for `FileDownloadedEvent` on `file_id`
      listen file_id, FileDownloadedEvent, :callback,
        owner_id: entity_id,
        subscriber: :unlisten_1

      # There's an entry for `file_id`
      assert [_] = ListenerQuery.get_listeners(file_id, FileDownloadedEvent)

      unlisten entity_id, file_id, FileDownloadedEvent, :unlisten_1

      # Entry is no more
      assert [] == ListenerQuery.get_listeners(file_id, FileDownloadedEvent)
    end
  end
end
