defmodule Helix.Software.Event.Cracker.Bruteforce do

  import Helix.Event

  event Processed do
    @moduledoc """
    BruteforceProcessedEvent is fired when a CrackerBruteforceProcess has
    completed its execution.
    """

    alias HELL.IPv4
    alias Helix.Entity.Model.Entity
    alias Helix.Network.Model.Network
    alias Helix.Process.Model.Process
    alias Helix.Server.Model.Server
    alias Helix.Software.Process.Cracker.Bruteforce,
      as: BruteforceProcess

    @type t :: %__MODULE__{
      source_entity_id: Entity.id,
      network_id: Network.id,
      target_server_ip: IPv4.t,
      target_server_id: Server.id,
    }

    event_struct [
      :source_entity_id,
      :network_id,
      :target_server_ip,
      :target_server_id
    ]

    @spec new(Process.t, BruteforceProcess.t) ::
      t
    def new(process = %Process{}, data = %BruteforceProcess{}) do
      %__MODULE__{
        source_entity_id: process.source_entity_id,
        network_id: process.network_id,
        target_server_id: process.target_server_id,
        target_server_ip: data.target_server_ip
      }
    end
  end

  event Failed do
    @moduledoc """
    BruteforceFailedEvent is fired when a CrackerBruteforceProcess has
    failed to completed.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server

    @type reason :: :nip_notfound | :internal

    @type t :: %__MODULE__{
      entity_id: Entity.id,
      network_id: Network.id,
      server_id: Server.id,
      server_ip: Network.ip,
      reason: reason
    }

    event_struct [
      :entity_id,
      :network_id,
      :server_id,
      :server_ip,
      :reason
    ]

    @spec new(Entity.id, Server.id, Network.id, Network.ip, reason) ::
      t
    def new(entity_id, server_id, network_id, ip, reason) do
      %__MODULE__{
        entity_id: entity_id,
        server_id: server_id,
        server_ip: ip,
        network_id: network_id,
        reason: reason
      }
    end
  end
end
