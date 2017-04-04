defmodule Helix.Event.Dispatcher do
  @moduledoc false

  use HELF.Event

  alias Helix.Software
  alias Helix.Network

  ##############################################################################
  # Network events
  ##############################################################################
  event Network.Model.ConnectionClosedEvent,
    Network.Service.Event.Tunnel,
    :connection_closed

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
