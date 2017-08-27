defmodule Helix.Event.Dispatcher.Notification do

  use HELF.Event

  alias Helix.Log
  alias Helix.Process
  alias Helix.Server

  ##############################################################################
  # Process notifications
  ##############################################################################

  event Process.Model.Process.ProcessCreatedEvent,
    Server.Websocket.Channel.Server.Events,
    :notification_handler

  event Process.Model.Process.ProcessConclusionEvent,
    Server.Websocket.Channel.Server.Events,
    :notification_handler

  ##############################################################################
  # Log notifications
  ##############################################################################
  event Log.Model.Log.LogCreatedEvent,
    Server.Websocket.Channel.Server.Events,
    :notification_handler

  event Log.Model.Log.LogModifiedEvent,
    Server.Websocket.Channel.Server.Events,
    :notification_handler

  event Log.Model.Log.LogDeletedEvent,
    Server.Websocket.Channel.Server.Events,
    :notification_handler
end
