defmodule Helix.Event do

  alias Helix.Event.Dispatcher

  # TODO: This type belongs to HELF.Event
  @type t :: struct

  def emit([]),
    do: :noop
  def emit(events = [_|_]),
    do: Enum.each(events, &emit/1)
  def emit(event),
    do: Dispatcher.emit(event)
end
