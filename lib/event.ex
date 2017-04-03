defmodule Helix.Event do

  alias Helix.Event.Dispatcher

  # TODO: This type belongs to HELF.Event
  @type t :: struct

  def emit(event),
    do: Dispatcher.emit(event)
end
