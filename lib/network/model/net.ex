defmodule Helix.Network.Model.Net do
  @moduledoc """
  `Net` is an internal struct able to fully represent the connection/tunnel
  context between two servers.
  """

  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel

  @enforce_keys [:network_id, :bounce_id]
  defstruct [:network_id, :bounce_id]

  @type t ::
  %__MODULE__{
    network_id: Network.id,
    bounce_id: term
  }

  @spec new(Network.id, term) ::
  t
  def new(network_id = %Network.ID{}, bounce_id) do
    %__MODULE__{
      network_id: network_id,
      bounce_id: bounce_id
    }
  end

  @spec new(Tunnel.t) ::
  t
  def new(tunnel = %Tunnel{}) do
    %__MODULE__{
      network_id: tunnel.network_id,
      bounce_id: []  # TODO 256
    }
  end
end
