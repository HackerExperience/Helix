defmodule Helix.Software.Model.Software.Cracker.Bruteforce.ConclusionEvent do

  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server

  @type t :: %__MODULE__{
    source_entity_id: Entity.id,
    network_id: Network.id,
    target_server_ip: IPv4.t,
    target_server_id: Server.id,
  }

  @enforce_keys ~w/
    source_entity_id
    network_id
    target_server_ip
    target_server_id
  /a
  defstruct ~w/
    source_entity_id
    network_id
    target_server_ip
    target_server_id
  /a
end

defmodule Helix.Server.Model.Server.PasswordAcquiredEvent do

  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server

  @type t :: %__MODULE__{
    source_entity_id: Entity.id,
    network_id: Network.id,
    target_server_id: Server.id,
    target_server_ip: IPv4.t,
    password: Server.password
  }

  @enforce_keys ~w/
    source_entity_id
    network_id
    target_server_ip
    target_server_id
    password
  /a
  defstruct ~w/
    source_entity_id
    network_id
    target_server_ip
    target_server_id
    password
  /a
end

defmodule Helix.Software.Model.Software.Cracker.Overflow.ConclusionEvent do

  alias Helix.Network.Model.Connection
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server

  @type t :: %__MODULE__{
    gateway_id: Server.id,
    target_process_id: Process.id | nil,
    target_connection_id: Connection.id | nil
  }

  @enforce_keys [:gateway_id, :target_process_id, :target_connection_id]
  defstruct [:gateway_id, :target_process_id, :target_connection_id]
end
