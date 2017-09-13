defmodule Helix.Network.Event.Connection do

  alias Helix.Event
  alias Helix.Universe.Bank.Model.BankTransfer.BankTransferCompletedEvent
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Query.Tunnel, as: TunnelQuery

  def bank_transfer_completed(e = %BankTransferCompletedEvent{}) do
    connection = TunnelQuery.fetch_connection(e.connection_id)
    event = TunnelAction.close_connection(connection)
    Event.emit(event)
  end
end
