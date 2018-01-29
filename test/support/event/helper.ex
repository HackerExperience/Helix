defmodule Helix.Test.Event.Helper do

  alias Helix.Event

  def emit(event),
    do: Event.emit(event)

  def get_process(event),
    do: Event.get_process(event)
end
