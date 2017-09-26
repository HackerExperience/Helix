defmodule Helix.Event.Dispatcher.Story do

  use HELF.Event

  alias Helix.Story.Event.Handler.Story, as: StoryHandler
  alias Helix.Universe
  alias Helix.Story

  event Story.Event.Reply.Sent,
    StoryHandler,
    :step_handler

  event Universe.Bank.Model.BankTransfer.BankTransferCompletedEvent,
    StoryHandler,
    :step_handler
end
