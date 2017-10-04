defmodule Helix.Event.Dispatcher.Notification do

  use HELF.Event

  alias Helix.Event.NotificationHandler
  alias Helix.Process
  alias Helix.Server

  alias Helix.Log.Event, as: LogEvent

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
  event LogEvent.Log.Created,
    NotificationHandler,
    :notification_handler

  event LogEvent.Log.Modified,
    NotificationHandler,
    :notification_handler

  event LogEvent.Log.Deleted,
    NotificationHandler,
    :notification_handler

  ##############################################################################
  # Server notifications
  ##############################################################################
  event Server.Model.Server.PasswordAcquiredEvent,
    NotificationHandler,
    :notification_handler
end
