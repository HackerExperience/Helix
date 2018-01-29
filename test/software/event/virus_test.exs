defmodule Helix.Software.Event.Virus.InstalledTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Log.Macros

  alias Helix.Log.Query.Log, as: LogQuery

  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Server.Helper, as: ServerHelper

  describe "event reactions" do
    test "logs are created" do
      {event, %{virus: virus}} =
        EventSetup.Software.file_install_processed(:virus)

      EventHelper.emit(event)

      process = EventHelper.get_process(event)

      entity_id = process.source_entity_id
      gateway_id = process.gateway_id
      target_id = process.target_id

      gateway_ip = ServerHelper.get_ip(gateway_id)
      target_ip = ServerHelper.get_ip(target_id)

      # Log saved on attacker (gateway)
      [log_gateway | _] = LogQuery.get_logs_on_server(gateway_id)
      assert_log \
        log_gateway, gateway_id, entity_id,
        "localhost installed virus",
        contains: [virus.name],
        rejects: [gateway_ip, target_ip]

      assert_bounce process.bounce_id, gateway_id, target_id, entity_id

      # Log saved on victim (target)
      [log_target | _] = LogQuery.get_logs_on_server(target_id)
      assert_log \
        log_target, target_id, entity_id,
        "at localhost",
        contains: ["installed virus", virus.name],
        rejects: [target_ip, target_ip]
    end
  end
end
