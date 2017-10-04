defmodule Helix.Log.Event.Handler.Log do
  @moduledoc false

  alias Helix.Event
  alias Helix.Log.Action.Log, as: LogAction
  alias Helix.Log.Model.Loggable
  alias Helix.Log.Query.Log, as: LogQuery

  alias Helix.Software.Model.SoftwareType.LogForge.Edit.ConclusionEvent,
    as: LogForgeEditComplete
  alias Helix.Software.Model.SoftwareType.LogForge.Create.ConclusionEvent,
    as: LogForgeCreateComplete

  @doc """
  Generic event handler for all Helix events. If the event implement the
  Loggable protocol, it will guide it through the LoggableFlow, making sure
  the relevant log entries are generated and saved
  """
  def handle_event(event) do
    if Loggable.impl_for(event) do
      event
      |> Loggable.generate()
      |> Loggable.Flow.save()
    end
  end

  @doc """
  Forges a revision onto a log or creates a fake new log
  """
  def log_forge_conclusion(event = %LogForgeEditComplete{}) do
    {:ok, _, events} =
      event.target_log_id
      |> LogQuery.fetch()
      |> LogAction.revise(event.entity_id, event.message, event.version)

    Event.emit(events)
  end

  def log_forge_conclusion(event = %LogForgeCreateComplete{}) do
    {:ok, _, events} = LogAction.create(
      event.target_server_id,
      event.entity_id,
      event.message,
      event.version)

    Event.emit(events)
  end
end
