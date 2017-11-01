defmodule Helix.Process.Event.Handler.TOP do
  @moduledoc false

  alias Helix.Event
  alias Helix.Network.Event.Connection.Closed, as: ConnectionClosedEvent
  alias Helix.Server.Model.Server
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Action.TOP, as: TOPAction
  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Process.Event.Process.Created, as: ProcessCreatedEvent
  alias Helix.Process.Event.TOP.BringMeToLife, as: TOPBringMeToLifeEvent

  def wake_me_up(event = %TOPBringMeToLifeEvent{}) do
    process = ProcessQuery.fetch(event.process_id)

    case TOPAction.complete(process) do
      {:ok, events} ->
        Event.emit(events)

      # Can't wake up
      {:error, _} ->
        # This shouldn't happen... recalculate the TOP just in case
        call_recalque(process.gateway_id)
    end
  end

  def recalque_handler(event = %ProcessCreatedEvent{confirmed: false}) do
    case call_recalque(event.process.gateway_id) do
      {true, _} ->
        event
        |> ProcessCreatedEvent.new()
        |> Event.emit(from: event)

      _ ->
        event
        # |> ProcessCreateFailedEvent.new()
        # |> Event.emit
    end
  end

  def recalque_handler(%_{confirmed: true}),
    do: :noop

  defp call_recalque(server_id = %Server.ID{}) do
    case TOPAction.recalque(server_id) do
      {:ok, processes, events} ->
        Event.emit(events)

        {true, processes}

      _ ->
        false
    end
  end

  # TODO: Ensure that the processes are killed (by making `kill` blocking
  #   probably)
  def connection_closed(event = %ConnectionClosedEvent{}) do
    event.connection.connection_id
    |> ProcessQuery.get_processes_on_connection()
    |> Enum.each(&ProcessAction.kill(&1, :connection_closed))
  end
end
