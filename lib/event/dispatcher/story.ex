defmodule Helix.Event.Dispatcher.Story do
  @moduledoc """
  Dispatcher for Story-related events. Basically, we listen to most in-game
  events and notify the player's current step, which will figure out whether
  that event is relevant to the current mission or not.
  """

  use HELF.Event

  alias Helix.Story.Event, as: StoryEvent
  alias Helix.Story.Event.Handler.Story, as: StoryHandler

  event StoryEvent.Reply.Sent,
    StoryHandler,
    :step_handler
end
