defmodule Helix.Test.Event.Helper do

  alias Helix.Event
  alias Helix.Event.State.Timer, as: EventStateTimer

  @doc """
  Emits an event (no relay)
  """
  def emit(event),
    do: Event.emit(event)

  @doc """
  Returns the underlying process (if any) of the event
  """
  def get_process(event),
    do: Event.get_process(event)

  @doc """
  Immediately emit all events that are awaiting for their timer to complete
  """
  def flush_timer,
    do: EventStateTimer.flush()
end
