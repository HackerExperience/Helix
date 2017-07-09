defmodule Helix.Event.Dispatcher do
  @moduledoc false

  use HELF.Event

  alias Helix.Account
  alias Helix.Entity
  alias Helix.Log
  alias Helix.Network
  alias Helix.Process
  alias Helix.Software
  alias Helix.Server

  ##############################################################################
  # Account events
  ##############################################################################
  event Account.Model.Account.AccountCreatedEvent,
    Account.Event.Account,
    :account_create

  ##############################################################################
  # Log events
  ##############################################################################
  event Log.Model.Log.LogCreatedEvent,
    Server.Websocket.Channel.Server,
    :event_log_created

  event Log.Model.Log.LogModifiedEvent,
    Server.Websocket.Channel.Server,
    :event_log_modified

  event Log.Model.Log.LogDeletedEvent,
    Server.Websocket.Channel.Server,
    :event_log_deleted

  ##############################################################################
  # Network events
  ##############################################################################
  event Network.Model.Connection.ConnectionClosedEvent,
    Network.Event.Tunnel,
    :connection_closed
  event Network.Model.Connection.ConnectionClosedEvent,
    Process.Event.TOP,
    :connection_closed

  event Network.Model.Connection.ConnectionStartedEvent,
    Log.Event.Log,
    :connection_started

  ##############################################################################
  # Process events
  ##############################################################################
  event Process.Model.Process.ProcessCreatedEvent,
    Server.Websocket.Channel.Server,
    :event_process_created

  event Process.Model.Process.ProcessConclusionEvent,
    Server.Websocket.Channel.Server,
    :event_process_conclusion

  ##############################################################################
  # Software events
  ##############################################################################
  event Software.Model.SoftwareType.Cracker.ProcessConclusionEvent,
    Entity.Event.HackDatabase,
    :cracker_conclusion

  event Software.Model.SoftwareType.Decryptor.ProcessConclusionEvent,
    Software.Event.Decryptor,
    :complete

  event Software.Model.SoftwareType.Encryptor.ProcessConclusionEvent,
    Software.Event.Encryptor,
    :complete

  event Software.Model.SoftwareType.FileDownload.ProcessConclusionEvent,
    Software.Event.FileDownload,
    :complete
  event Software.Model.SoftwareType.FileDownload.ProcessConclusionEvent,
    Log.Event.Log,
    :file_download_conclusion

  event Software.Model.SoftwareType.Firewall.FirewallStartedEvent,
    Process.Event.Cracker,
    :firewall_started

  event Software.Model.SoftwareType.Firewall.FirewallStoppedEvent,
    Process.Event.Cracker,
    :firewall_stopped

  event Software.Model.SoftwareType.LogDeleter.ProcessConclusionEvent,
    Log.Event.Log,
    :log_deleter_conclusion
end
