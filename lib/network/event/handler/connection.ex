defmodule Helix.Network.Event.Handler.Connection do

  alias Helix.Event
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Query.Tunnel, as: TunnelQuery

  alias Helix.Universe.Bank.Event.Bank.Transfer.Processed,
    as: BankTransferProcessedEvent

  def bank_transfer_processed(e = %BankTransferProcessedEvent{}) do
    connection = TunnelQuery.fetch_connection(e.connection_id)
    event = TunnelAction.close_connection(connection)
    Event.emit(event, from: e)
  end
end
