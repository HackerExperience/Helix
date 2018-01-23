defmodule Helix.Software.Process.Cracker.BruteforceTest do

  use Helix.Test.Case.Integration

  alias Helix.Entity.Model.Entity
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Process.Model.Processable
  alias Helix.Process.Public.View.Process, as: ProcessView
  alias Helix.Software.Process.Cracker.Bruteforce, as: BruteforceProcess

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Process.Helper, as: ProcessHelper
  alias Helix.Test.Process.Setup, as: ProcessSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Process.View.Helper, as: ProcessViewHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @relay nil

  describe "Process.Executable" do
    test "starts the bruteforce process when everything is OK" do
      {source_server, %{entity: source_entity}} = ServerSetup.server()
      {target_server, _} = ServerSetup.server()

      {file, _} =
        SoftwareSetup.file([type: :cracker, server_id: source_server.server_id])

      target_nip = ServerHelper.get_nip(target_server)

      params = %{
        target_server_ip: target_nip.ip
      }

      meta = %{
        network_id: target_nip.network_id,
        bounce_id: nil,
        cracker: file
      }

      # Executes Cracker.bruteforce against the target server
      assert {:ok, process} =
        BruteforceProcess.execute(
          source_server, target_server, params, meta, @relay
        )

      # Process data is correct
      assert process.src_connection_id
      assert process.src_file_id == file.file_id
      assert process.type == :cracker_bruteforce
      assert process.gateway_id == source_server.server_id
      assert process.source_entity_id == source_entity.entity_id
      assert process.target_id == target_server.server_id
      assert process.network_id == target_nip.network_id
      assert process.data.target_server_ip == target_nip.ip

      # Bruteforce process has no target file or target connection
      refute process.tgt_file_id
      refute process.tgt_connection_id

      # CrackerBruteforce connection is correct
      connection = TunnelQuery.fetch_connection(process.src_connection_id)

      assert connection.connection_type == :cracker_bruteforce

      # Underlying tunnel is correct
      tunnel = TunnelQuery.fetch(connection.tunnel_id)

      assert tunnel.gateway_id == source_server.server_id
      assert tunnel.destination_id == target_server.server_id
      assert tunnel.network_id == target_nip.network_id

      TOPHelper.top_stop(source_server)
      CacheHelper.sync_test()
    end
  end

  describe "Process.Viewable" do
    test "full process for any AT attack_source" do
      {process, meta} =
        ProcessSetup.process(fake_server: true, type: :bruteforce)
      data = process.data
      server_id = process.gateway_id

      attacker_id = meta.source_entity_id
      victim_id = meta.target_entity_id
      third_id = Entity.ID.generate()

      # Here we cover all possible cases on `attack_source`, so regardless of
      # *who* is listing the processes, as long as it's on the `attack_source`,
      # they have full access to the process.
      pview_attacker = ProcessView.render(data, process, server_id, attacker_id)
      pview_victim = ProcessView.render(data, process, server_id, victim_id)
      pview_third = ProcessView.render(data, process, server_id, third_id)

      ProcessViewHelper.assert_keys(pview_attacker, :full)
      ProcessViewHelper.assert_keys(pview_victim, :full)
      ProcessViewHelper.assert_keys(pview_third, :full)

      TOPHelper.top_stop()
    end

    test "full process for attacker AT attack_target" do
      {process, %{source_entity_id: entity_id}} =
        ProcessSetup.process(fake_server: true, type: :bruteforce)

      data = process.data
      server_id = process.target_id

      # `entity` is the one who started the process, and is listing at the
      # victim server, so `entity` has full access to the process.
      rendered = ProcessView.render(data, process, server_id, entity_id)

      ProcessViewHelper.assert_keys(rendered, :full)

      TOPHelper.top_stop()
    end

    test "partial process for third AT attack_target" do
      {process, _} = ProcessSetup.process(fake_server: true, type: :bruteforce)

      data = process.data
      server_id = process.target_id
      entity_id = Entity.ID.generate()

      # `entity` is unrelated to the process, and it's being rendering on the
      # receiving end of the process (victim), so partial access is applied.
      rendered = ProcessView.render(data, process, server_id, entity_id)

      ProcessViewHelper.assert_keys(rendered, :partial)

      TOPHelper.top_stop()
    end

    test "partial process for victim AT attack_target" do
      {process, %{target_entity_id: entity_id}} =
        ProcessSetup.process(fake_server: true, type: :bruteforce)

      data = process.data
      server_id = process.target_id

      # `entity` is the victim, owner of the server receiving the process.
      # She's rendering at her own server, but she did not start the process,
      # so she has limited access to the process.
      rendered = ProcessView.render(data, process, server_id, entity_id)

      ProcessViewHelper.assert_keys(rendered, :partial)

      TOPHelper.top_stop()
    end
  end

  describe "Processable" do
    test "after_read_hook/1" do
      {process, _} = ProcessSetup.process(fake_server: true, type: :bruteforce)

      db_process = ProcessHelper.raw_get(process.process_id)

      serialized = Processable.after_read_hook(db_process.data)

      assert serialized.target_server_ip

      TOPHelper.top_stop()
    end
  end
end
