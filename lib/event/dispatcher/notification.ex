defmodule Helix.Event.Dispatcher.Notification do

  use HELF.Event

  alias Helix.Event.NotificationHandler
  alias Helix.Log
  alias Helix.Process
  alias Helix.Server

  ##############################################################################
  # Process notifications
  ##############################################################################
  event Process.Model.Process.ProcessCreatedEvent,
    NotificationHandler,
    :notification_handler

  event Process.Model.Process.ProcessConclusionEvent,
    NotificationHandler,
    :notification_handler

  ##############################################################################
  # Log notifications
  ##############################################################################
  event Log.Model.Log.LogCreatedEvent,
    NotificationHandler,
    :notification_handler

  event Log.Model.Log.LogModifiedEvent,
    NotificationHandler,
    :notification_handler

  event Log.Model.Log.LogDeletedEvent,
    NotificationHandler,
    :notification_handler

  ##############################################################################
  # Server notifications
  ##############################################################################
  event Server.Model.Server.PasswordAcquiredEvent,
    NotificationHandler,
    :notification_handler
end

defmodule Helix.Event.Dispatcher.Story do

  use HELF.Event

  alias Helix.Story.Event.Handler.Story, as: StoryHandler
  alias Helix.Universe

  event Universe.Bank.Model.BankTransfer.BankTransferCompletedEvent,
    StoryHandler,
    :step_handler
end
