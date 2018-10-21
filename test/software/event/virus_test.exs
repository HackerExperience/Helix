defmodule Helix.Software.Event.Virus.InstalledTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Log.Macros

  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Log.Helper, as: LogHelper

  describe "event reactions" do
    test "logs are created" do
      {event, _} = EventSetup.Software.file_install_processed(:virus)

      EventHelper.emit(event)

      process = EventHelper.get_process(event)

      entity_id = process.source_entity_id
      gateway_id = process.gateway_id
      target_id = process.target_id

      file_name = LogHelper.log_file_name(event.file)

      # Log saved on attacker (gateway)
      log_gateway = LogHelper.get_last_log(gateway_id, :virus_installed_gateway)
      assert_log log_gateway, gateway_id, entity_id,
        :virus_installed_gateway, %{file_name: file_name}

      assert_bounce process.bounce_id, gateway_id, target_id, entity_id

      # Log saved on victim (target)
      log_target = LogHelper.get_last_log(target_id, :virus_installed_endpoint)
      assert_log log_target, target_id, entity_id,
        :virus_installed_endpoint, %{file_name: file_name}
    end
  end
end
