defmodule Helix.Event do

  alias Helix.Event.Dispatcher.Helix, as: HelixDispatcher
  alias Helix.Event.Dispatcher.Notification, as: NotificationDispatcher
  alias Helix.Event.Dispatcher.Story, as: StoryDispatcher

  @type t :: HELF.Event.t

  def emit([]),
    do: :noop
  def emit(events = [_|_]),
    do: Enum.each(events, &emit/1)
  def emit(event) do
    HelixDispatcher.emit(event)
    NotificationDispatcher.emit(event)
    StoryDispatcher.emit(event)
  end
end
