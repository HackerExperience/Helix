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
    :event_process_created

  event Process.Model.Process.ProcessConclusionEvent,
    Server.Websocket.Channel.Server.Events,
    :event_process_conclusion

  ##############################################################################
  # Log notifications
  ##############################################################################
  event Log.Model.Log.LogCreatedEvent,
    Server.Websocket.Channel.Server.Events,
    :event_log_created

  event Log.Model.Log.LogModifiedEvent,
    Server.Websocket.Channel.Server.Events,
    :event_log_modified

  event Log.Model.Log.LogDeletedEvent,
    Server.Websocket.Channel.Server.Events,
    :event_log_deleted
end
