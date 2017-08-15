defmodule Helix.Universe.Bank.Action.Flow.BankTransferTest do

  use Helix.Test.IntegrationCase

  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Universe.Bank.Action.Flow.BankTransfer, as: BankTransferFlow
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal

  alias HELL.TestHelper.Setup
  alias Helix.Test.Process.TOPHelper

  describe "start/1" do
    @tag :slow
    test "default life cycle (different atms)" do
      amount = 1
      acc1 = Setup.bank_account([balance: amount, atm_seq: 1])
      acc2 = Setup.bank_account([atm_seq: 2])
      {gateway, player} = Setup.server()

      # They see me flowin', they hatin'
      {:ok, process} = BankTransferFlow.start(acc1, acc2, amount, player)
      transfer_id = process.process_data.transfer_id

      # Transfer was added to the DB
      assert BankTransferInternal.fetch(transfer_id)

      # Ensure process was created
      assert ProcessQuery.fetch(process.process_id)

      # Wire transfer connection was created
      assert process.connection_id
      connection = TunnelQuery.fetch_connection(process.connection_id)
      assert connection.connection_id == process.connection_id
      assert connection.connection_type == :wire_transfer

      # Wire transfer bounce is correct
      tunnel = TunnelQuery.fetch(connection.tunnel_id)
      assert tunnel.gateway_id == gateway.server_id
      assert tunnel.destination_id == acc2.atm_id
      hops = TunnelQuery.get_hops(tunnel.tunnel_id)
      assert hops == [gateway.server_id, acc1.atm_id, acc2.atm_id]

      # Removed money from source, but did not transfer yet
      assert BankAccountInternal.get_balance(acc1) == 0
      assert BankAccountInternal.get_balance(acc2) == 0

      # Wait for it.... Transferring $0.01 is quite quick (nope)
      :timer.sleep(1100)

      # Transfer was completed
      refute BankTransferInternal.fetch(transfer_id)
      refute ProcessQuery.fetch(process.process_id)
      assert BankAccountInternal.get_balance(acc1) == 0
      assert BankAccountInternal.get_balance(acc2) == amount

      # Wire transfer connection was deleted
      refute TunnelQuery.fetch_connection(process.connection_id)
      refute TunnelQuery.fetch(connection.tunnel_id)

      TOPHelper.top_stop(process.gateway_id)
    end
  end

  test "wire transfer on same atm" do
    amount = 1
    acc1 = Setup.bank_account([balance: amount, atm_seq: 1])
    acc2 = Setup.bank_account([atm_seq: 1])
    {gateway, player} = Setup.server()

    {:ok, process} = BankTransferFlow.start(acc1, acc2, amount, player)

    # Get connection data
    connection = TunnelQuery.fetch_connection(process.connection_id)
    tunnel = TunnelQuery.fetch(connection.tunnel_id)

    # Bounce is correct
    assert tunnel.gateway_id == gateway.server_id
    assert tunnel.destination_id == acc2.atm_id
    hops = TunnelQuery.get_hops(tunnel.tunnel_id)
    assert hops == [gateway.server_id, acc2.atm_id]

    TOPHelper.top_stop(process.gateway_id)
  end
end
