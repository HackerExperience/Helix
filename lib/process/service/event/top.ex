defmodule Helix.Process.Service.Event.TOP do
  @moduledoc false

  alias Helix.Network.Model.ConnectionClosedEvent
  alias Helix.Process.Service.API.Process, as: API

  # TODO: Ensure that the processes are killed (by making `kill` blocking
  #   probably)
  def connection_closed(%ConnectionClosedEvent{connection_id: connection}) do
    connection
    |> API.get_processes_on_connection()
    |> Enum.each(&API.kill(&1, :connection_closed))
  end
end
