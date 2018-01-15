defmodule Helix.Process.Event.Handler.TOP do
  @moduledoc false

  import HELL.Macros

  alias Helix.Event
  alias Helix.Network.Event.Connection.Closed, as: ConnectionClosedEvent
  alias Helix.Process.Action.Flow.Process, as: ProcessFlow
  alias Helix.Process.Action.TOP, as: TOPAction
  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Process.Event.Process.Created, as: ProcessCreatedEvent
  alias Helix.Process.Event.TOP.BringMeToLife, as: TOPBringMeToLifeEvent

  @doc """
  `wake_me_up` is a handler for the `TOPBringMeToLifeEvent`, which is fired at
  the moment a process is expected to be completed.

  May emit ProcessCompletedEvent
  """
  def wake_me_up(event = %TOPBringMeToLifeEvent{}) do
    process = ProcessQuery.fetch(event.process_id)

    if process do
      case TOPAction.complete(process) do
        {:ok, events} ->
          Event.emit(events, from: event)
          # Recalque again, since now the server has more available resources
          call_recalque(process, event)

        # Can't wake up
        {:error, {:process, :running}} ->
          # Weird but could happen. Recalculate the TOP just in case
          # HACK: The `silent: true` is hack-ish. See #326 for more context.
          call_recalque(process, event, silent: true)
      end
    end
  end

  @doc """
  `recalque_handler` is a generic handler for events that should cause a TOP
  recalculation.

  Emits ProcessCreatedEvent or ProcessCreateFailedEvent
  """
  def recalque_handler(event = %ProcessCreatedEvent{confirmed: false}) do
    case call_recalque(event.process, event) do
      {true, _} ->
        event
        |> ProcessCreatedEvent.new()
        |> Event.emit(from: event)

      {false, _} ->
        # TODO
        :todo
        # event
        # |> ProcessCreateFailedEvent.new()
        # |> Event.emit
    end
  end

  def recalque_handler(%_{confirmed: true}),
    do: :noop

  @spec call_recalque(Process.t, Event.t) ::
    {gateway_recalque :: boolean, target_recalque :: boolean}
  defp call_recalque(process = %Process{}, source_event, opts \\ []) do
    %{gateway: gateway_recalque, target: target_recalque} =
      TOPAction.recalque(process, source: source_event)

    gateway_recalque =
      case gateway_recalque do
        {:ok, _processes, events} ->
          unless opts[:silent] do
            Event.emit(events, from: source_event)
          end
          true

        _ ->
          false
      end

    target_recalque =
      case target_recalque do
        {:ok, _processes, events} ->
          unless opts[:silent] do
            Event.emit(events, from: source_event)
          end
          true

        :noop ->
          true

        _ ->
          false
      end

    {gateway_recalque, target_recalque}
  end

  @doc """
  Handler for changes in objects that might be of interest to some processes.

  These objects are, for instance, connections or files or logs that may be in
  use by a process.

  Notice that if the received event was emitted from a process, this process
  won't receive the corresponding signal. See `filter_self_message/2`.
  """
  def object_handler(event = %ConnectionClosedEvent{}) do
    signal_param = %{connection: event.connection}

    # Send SIGSRCCONND for processes that originated on such connection
    event.connection.connection_id
    |> ProcessQuery.get_processes_originated_on_connection()
    |> filter_self_message(event)
    |> Enum.each(&ProcessFlow.signal(&1, :SIGSRCCONND, signal_param))

    # Send SIGTGTCONND for processes that are targeting such connection
    event.connection.connection_id
    |> ProcessQuery.get_processes_targeting_connection()
    |> filter_self_message(event)
    |> Enum.each(&ProcessFlow.signal(&1, :SIGTGTCONND, signal_param))
  end

  docp """
  `filter_self_message/2` filters events related to element changes (connection
  closed, file deleted, log deleted) that were inflicted by the process itself.

  Imagine the following scenario:

  The `FileDeleteProcess` has completed, and received a SIGTERM. It will emit
  the `FileDeleteProcessedEvent`, which will delete the corresponding file,
  eventually emitting `FileDeletedEvent`.

  Meanwhile, TOP will receive the `ProcessSignaledEvent` with the Processable's
  action, in our case asking to delete the process.

  Imagine, however, that `ProcessSignaledEvent` takes really long to arrive. It
  could happen that `FileDeletedEvent` arrives first. Now, it's the TOPHandler's
  role to listen to `FileDeletedEvent`s and emit a SIGTGTFILED on all processes
  that target that file, including our recently completed process.

  This would not create an infinite loop, but it would affect the expected
  behavior of TOP, FileDelete completion, or both. It is quite rare to happen
  on production, but it will deterministically happen on tests, since all
  `spawned` processes are actually synchronous under the test environment.

  To avoid this scenario, we make sure that the process won't be notified of
  events that the process itself generated.

  Notice this only applies to elements, like changes to underlying files and
  connections. A process may still send a signal to itself, directly, using the
  corresponding `Processable` action.
  """
  defp filter_self_message(processes, event) do
    process_id = Event.get_process_id(event)

    Enum.reject(processes, &(&1.process_id == process_id))
  end
end
