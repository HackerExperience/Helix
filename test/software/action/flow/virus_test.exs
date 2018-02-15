defmodule Helix.Software.Action.Flow.VirusTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Software.Action.Flow.Virus, as: VirusFlow

  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @relay nil

  describe "start_collect/5" do
    test "starts virus collect" do
      {gateway, %{entity: entity}} = ServerSetup.server()

      {target1, _} = ServerSetup.server()
      {target2, _} = ServerSetup.server()

      storage1_id = SoftwareHelper.get_storage_id(target1)
      storage2_id = SoftwareHelper.get_storage_id(target2)

      {_virus1, %{file: file1}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity.entity_id,
          storage_id: storage1_id,
          real_file?: true
        )

      # use a `miner` once available (#244)
      {_virus2, %{file: file2}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity.entity_id,
          storage_id: storage2_id,
          real_file?: true
        )

      viruses = [{file1, target1}, {file2, target2}]

      {bank_acc, _} = BankSetup.fake_account()
      wallet = nil

      {bounce, _} = NetworkSetup.Bounce.bounce()

      assert [process1, process2] =
        VirusFlow.start_collect(
          gateway, viruses, bounce.bounce_id, {bank_acc, wallet}, @relay
        )

      # Collect of file1:
      assert process1.type == :virus_collect
      assert process1.gateway_id == gateway.server_id
      assert process1.target_id == target1.server_id
      assert process1.source_entity_id == entity.entity_id
      assert process1.src_connection_id
      assert process1.src_file_id == file1.file_id
      assert process1.bounce_id == bounce.bounce_id
      assert process1.tgt_atm_id == bank_acc.atm_id
      assert process1.tgt_acc_number == bank_acc.account_number
      refute process1.data.wallet

      # Collect of file2:
      assert process2.type == :virus_collect
      assert process2.gateway_id == gateway.server_id
      assert process2.target_id == target2.server_id
      assert process2.source_entity_id == entity.entity_id
      assert process2.src_connection_id
      assert process2.src_file_id == file2.file_id
      assert process2.bounce_id == bounce.bounce_id
      assert process2.tgt_atm_id == bank_acc.atm_id
      assert process2.tgt_acc_number == bank_acc.account_number
      refute process2.data.wallet

      # Make sure the connections were created as well
      connection1 = TunnelQuery.fetch_connection(process1.src_connection_id)
      tunnel1 = TunnelQuery.fetch_from_connection(connection1)

      # Connection has the right type
      assert connection1.connection_type == :virus_collect

      # Underlying tunnel was created and it only contains `virus_collect` conn
      assert tunnel1.bounce == bounce
      assert [connection1] == TunnelQuery.get_connections(tunnel1)

      # Same for `file2`...
      connection2 = TunnelQuery.fetch_connection(process2.src_connection_id)
      tunnel2 = TunnelQuery.fetch_from_connection(connection2)

      # Connection has the right type
      assert connection2.connection_type == :virus_collect

      # Underlying tunnel was created and it only contains `virus_collect` conn
      assert tunnel2.bounce == bounce
      assert [connection2] == TunnelQuery.get_connections(tunnel2)

      TOPHelper.top_stop()
    end
  end
end
