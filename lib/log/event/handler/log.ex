defmodule Helix.Log.Event.Handler.Log do
  @moduledoc false

  alias Helix.Event
  alias Helix.Event.Loggable
  alias Helix.Log.Action.Log, as: LogAction
  alias Helix.Log.Model.Log
  alias Helix.Log.Query.Log, as: LogQuery

  alias Helix.Log.Event.Forge.Processed, as: LogForgeProcessedEvent

  @doc """
  Generic event handler for all Helix events. If the event implement the
  Loggable protocol, it will guide it through the LoggableFlow, making sure
  the relevant log entries are generated and saved

  Emits `LogCreatedEvent`
  """
  def handle_event(event) do
    if Loggable.impl_for(event) do
      event
      |> Loggable.generate()
      |> Loggable.Flow.save()
      |> Event.emit(from: event)
    end
  end

  @doc """
  Handler called right after a `LogForgeProcess` has completed. It will then
  either create a new log out of thin air, or edit an existing log.

  Emits: `LogCreatedEvent`, `LogRevisedEvent`
  """
  def log_forge_processed(event = %LogForgeProcessedEvent{action: :create}) do
    # `action` is `:create`, so we'll create a new log out of thin air!
    result =
      LogAction.create(
        event.server_id, event.entity_id, event.log_info, event.forger_version
      )

    with {:ok, _, events} <- result do
      Event.emit(events)
    end
  end

  def log_forge_processed(event = %LogForgeProcessedEvent{action: :edit}) do
    # `action` is `:edit`, so we'll stack up a revision on an existing log
    revise = fn log ->
      LogAction.revise(
        log, event.entity_id, event.log_info, event.forger_version
      )
    end

    with \
      log = %Log{} <- LogQuery.fetch(event.target_log_id),
      {:ok, _, events} <- revise.(log)
    do
      Event.emit(events)
    end
  end
end
