defmodule Helix.Process.Event.TOP do
  @moduledoc false

  alias Helix.Network.Model.Connection.ConnectionClosedEvent
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Process.Action.Process, as: ProcessAction

  # TODO: Ensure that the processes are killed (by making `kill` blocking
  #   probably)
  def connection_closed(%ConnectionClosedEvent{connection_id: connection}) do
    connection
    |> ProcessQuery.get_processes_on_connection()
    |> Enum.each(&ProcessAction.kill(&1, :connection_closed))
  end
end
