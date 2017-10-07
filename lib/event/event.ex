defmodule Helix.Event do

  alias Helix.Event.Dispatcher, as: HelixDispatcher

  @type t :: HELF.Event.t

  def emit([]),
    do: :noop
  def emit(events = [_|_]),
    do: Enum.each(events, &emit/1)
  def emit(event),
    do: HelixDispatcher.emit(event)
end
