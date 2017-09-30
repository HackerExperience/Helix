defmodule Helix.Event.Dispatcher.Story do

  use HELF.Event

  alias Helix.Story.Event, as: StoryEvent
  alias Helix.Story.Event.Handler.Story, as: StoryHandler

  event StoryEvent.Reply.Sent,
    StoryHandler,
    :step_handler
end
