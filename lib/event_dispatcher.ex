defmodule Helix.Event.Dispatcher do
  @moduledoc false

  use HELF.Event

  alias Helix.Network
  alias Helix.Process
  alias Helix.Software

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
