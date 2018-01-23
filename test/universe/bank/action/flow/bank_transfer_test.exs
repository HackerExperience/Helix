defmodule Helix.Universe.Bank.Action.Flow.BankTransferTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Universe.Bank.Action.Flow.BankTransfer, as: BankTransferFlow
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal

  alias Helix.Test.Account.Setup, as: AccountSetup
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  @relay nil

  describe "start/1" do
    @tag :slow
    test "default life cycle (different atms)" do
      amount = 1
      {acc1, _} = BankSetup.account([balance: amount, atm_seq: 1])
      {acc2, _} = BankSetup.account([atm_seq: 2])
      {player, %{server: gateway}} = AccountSetup.account([with_server: true])

      {tunnel, _} =
        NetworkSetup.tunnel(
          gateway_id: gateway.server_id, destination_id: acc1.atm_id
        )

      # They see me flowin', they hatin'
      {:ok, process} =
        BankTransferFlow.start(
          acc1, acc2, amount, player, gateway, tunnel, @relay
        )
      transfer_id = process.data.transfer_id

      # Transfer was added to the DB
      assert BankTransferInternal.fetch(transfer_id)

      # Ensure process was created
      assert ProcessQuery.fetch(process.process_id)

      # Wire transfer connection was created
      assert process.src_connection_id
      connection = TunnelQuery.fetch_connection(process.src_connection_id)
      assert connection.connection_id == process.src_connection_id
      assert connection.connection_type == :wire_transfer

      # Wire transfer bounce is correct
      tunnel = TunnelQuery.fetch(connection.tunnel_id)
      assert tunnel.gateway_id == gateway.server_id
      assert tunnel.destination_id == acc2.atm_id

      # TODO: #379
      # hops = TunnelQuery.get_hops(tunnel)
      #assert hops == [gateway.server_id, acc1.atm_id, acc2.atm_id]

      # Removed money from source, but did not transfer yet
      assert BankAccountInternal.get_balance(acc1) == 0
      assert BankAccountInternal.get_balance(acc2) == 0

      # Magically finish the process
      TOPHelper.force_completion(process)

      # Transfer was completed
      refute BankTransferInternal.fetch(transfer_id)
      refute ProcessQuery.fetch(process.process_id)
      assert BankAccountInternal.get_balance(acc1) == 0
      assert BankAccountInternal.get_balance(acc2) == amount

      # Wire transfer connection was deleted
      refute TunnelQuery.fetch_connection(process.src_connection_id)
      refute TunnelQuery.fetch(connection.tunnel_id)

      TOPHelper.top_stop(gateway)
    end
  end

  test "wire transfer on same atm" do
    amount = 1
    {acc1, _} = BankSetup.account([balance: amount, atm_seq: 1])
    {acc2, _} = BankSetup.account([atm_seq: 1])
    {player, %{server: gateway}} = AccountSetup.account([with_server: true])

    {tunnel, _} =
      NetworkSetup.tunnel(
        gateway_id: gateway.server_id, destination_id: acc1.atm_id
      )

    {:ok, process} =
      BankTransferFlow.start(
        acc1, acc2, amount, player, gateway, tunnel, @relay
      )

    # Get connection data
    connection = TunnelQuery.fetch_connection(process.src_connection_id)
    tunnel = TunnelQuery.fetch(connection.tunnel_id)

    # Bounce is correct
    assert tunnel.gateway_id == gateway.server_id
    assert tunnel.destination_id == acc2.atm_id

    hops = TunnelQuery.get_hops(tunnel)
    assert hops == [gateway.server_id, acc2.atm_id]

    TOPHelper.top_stop(gateway)
  end
end
