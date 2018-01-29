defmodule Helix.Software.Event.Handler.VirusTest do

  use Helix.Test.Case.Integration

  alias Helix.Software.Query.Virus, as: VirusQuery

  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Event.Setup, as: EventSetup

  describe "handling of FileInstallProcessedEvent" do
    test "installs the virus" do
      {event, _} = EventSetup.Software.file_install_processed(:virus)

      # Nothing installed
      assert Enum.empty?(VirusQuery.list_by_entity(event.entity_id))

      # Simulate event emission
      EventHelper.emit(event)

      # Virus has been installed!
      assert [virus] = VirusQuery.list_by_entity(event.entity_id)

      assert virus.file_id == event.file.file_id
      assert virus.is_active?
    end
  end
end
