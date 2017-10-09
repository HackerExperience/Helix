defmodule Helix.Software.Action.Flow.Software.CrackerTest do

  use Helix.Test.Case.Integration

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Software.Action.Flow.Software.Cracker, as: CrackerFlow

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "execute_cracker/4 for 'bruteforce' module" do
    test "starts the bruteforce process when everything is OK" do
      {source_server, %{entity: source_entity}} = ServerSetup.server()
      {target_server, _} = ServerSetup.server()

      {:ok, [target_nip]} =
        CacheQuery.from_server_get_nips(target_server.server_id)

      {file, _} =
        SoftwareSetup.file([type: :cracker, server_id: source_server.server_id])

      params = %{
        target_server_id: target_server.server_id,
        network_id: target_nip.network_id,
        target_server_ip: target_nip.ip
      }

      meta = %{
        bounces: []
      }

      # Executes Cracker.bruteforce against the target server
      assert {:ok, process} =
        CrackerFlow.execute(file, source_server.server_id, params, meta)

      # Process data is correct
      assert process.connection_id
      assert process.file_id == file.file_id
      assert process.process_type == "cracker_bruteforce"
      assert process.gateway_id == source_server.server_id
      assert process.source_entity_id == source_entity.entity_id
      assert process.process_data.target_server_id == target_server.server_id
      assert process.process_data.network_id == target_nip.network_id
      assert process.process_data.target_server_ip == target_nip.ip

      # CrackerBruteforce connection is correct
      connection = TunnelQuery.fetch_connection(process.connection_id)

      assert connection.connection_type == :cracker_bruteforce

      # Underlying tunnel is correct
      tunnel = TunnelQuery.fetch(connection.tunnel_id)

      assert tunnel.gateway_id == source_server.server_id
      assert tunnel.destination_id == target_server.server_id
      assert tunnel.network_id == target_nip.network_id

      :timer.sleep(100)
      TOPHelper.top_stop(source_server)
      CacheHelper.sync_test()
    end
  end
end
