defmodule Helix.Event.Dispatcher do
  @moduledoc false

  use HELF.Event

  alias Helix.Network
  alias Helix.Process
  alias Helix.Software
  alias Helix.Server

  ##############################################################################
  # Network events
  ##############################################################################
  event Network.Model.ConnectionClosedEvent,
    Network.Service.Event.Tunnel,
    :connection_closed

  ##############################################################################
  # Process events
  ##############################################################################
  event Process.Model.Process.ProcessCreatedEvent,
    Process.Service.Event.TOP,
    :process_created
  event Process.Model.Process.ProcessCreatedEvent,
    Server.Websocket.Channel.Server,
    :event_process_created

  event Process.Model.Process.ProcessConclusionEvent,
    Server.Websocket.Channel.Server,
    :event_process_conclusion

  ##############################################################################
  # Software events
  ##############################################################################
  event Software.Model.SoftwareType.Encryptor.ProcessConclusionEvent,
    Software.Service.Event.Encryptor,
    :complete

  event Software.Model.SoftwareType.Decryptor.ProcessConclusionEvent,
    Software.Service.Event.Decryptor,
    :complete
end
