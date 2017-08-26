defmodule Helix.Event do

  alias Helix.Event.Dispatcher.Helix, as: HelixDispatcher
  alias Helix.Event.Dispatcher.Notification, as: NotificationDispatcher

  # TODO: This type belongs to HELF.Event
  @type t :: struct

  def emit([]),
    do: :noop
  def emit(events = [_|_]),
    do: Enum.each(events, &emit/1)
  def emit(event) do
    HelixDispatcher.emit(event)
    NotificationDispatcher.emit(event)
  end
end
