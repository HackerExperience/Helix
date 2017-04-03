defmodule Helix.Event do

  alias Helix.Event.Dispatcher

  def emit(event),
    do: Dispatcher.emit(event)
end
