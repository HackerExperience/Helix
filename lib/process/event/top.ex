defmodule Helix.Process.Event.TOP do
  @moduledoc false

  alias Helix.Network.Event.Connection.Closed, as: ConnectionClosedEvent
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Process.Action.Process, as: ProcessAction

  # TODO: Ensure that the processes are killed (by making `kill` blocking
  #   probably)
  def connection_closed(event = %ConnectionClosedEvent{}) do
    event.connection.connection_id
    |> ProcessQuery.get_processes_on_connection()
    |> Enum.each(&ProcessAction.kill(&1, :connection_closed))
  end
end
