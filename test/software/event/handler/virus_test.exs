defmodule Helix.Software.Event.Handler.VirusTest do

  use Helix.Test.Case.Integration

  alias Helix.Software.Query.Virus, as: VirusQuery

  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "virus_installed/1" do
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

  describe "handle_collect/1" do
    test "collects earnings of money-based virus" do
      {_, %{file: file}} =
        SoftwareSetup.Virus.virus(type: :virus_spyware, running_time: 600)

      event = EventSetup.Software.Virus.collect_processed(file: file)

      # Emit the `VirusCollectProcessedEvent`
      EventHelper.emit(event)

      # Virus running time has been updated
      virus = VirusQuery.fetch(file.file_id)
      assert virus.running_time == 0
      assert virus.is_active?
    end
  end
end
