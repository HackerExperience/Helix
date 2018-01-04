defmodule Helix.Network.Action.Network.Connection do

  alias Helix.Server.Model.Component
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Network.Internal.Network, as: NetworkInternal

  @spec create(Network.idt, Network.ip, Entity.idt, Component.idt | nil) ::
    {:ok, Network.Connection.t}
    | {:error, :internal}
  @doc """
  Creates a new Network Connection with the given NIP (network_id, ip) and owned
  by `entity`. In case a nic is passed, the resulting NC is automatically
  assigned to it.
  """
  def create(network, ip, entity, nic \\ nil) do
    case NetworkInternal.Connection.create(network, ip, entity, nic) do
      {:ok, nc} ->
        {:ok, nc}

      {:error, _} ->
        {:error, :internal}
    end
  end

  @spec update_ip(Network.Connection.t, Network.ip) ::
    {:ok, Network.Connection.t}
    | {:error, :internal}
  @doc """
  Updates the NetworkConnection's IP. Called when player resets his/her IP.
  """
  def update_ip(nc = %Network.Connection{}, new_ip) do
    case NetworkInternal.Connection.update_ip(nc, new_ip) do
      {:ok, nc} ->
        {:ok, nc}

      {:error, _} ->
        {:error, :internal}
    end
  end

  @spec update_nic(Network.Connection.t, Component.nic | nil) ::
    {:ok, Network.Connection.t}
    | {:error, :internal}
  @doc """
  Updates the NetworkConnection's NIC. Used when player changes NIC, unassigns
  connections, etc.
  """
  def update_nic(nc = %Network.Connection{}, new_nic) do
    case NetworkInternal.Connection.update_nic(nc, new_nic) do
      {:ok, nc} ->
        {:ok, nc}

      {:error, _} ->
        {:error, :internal}
    end
  end

  @spec delete(Network.Connection.t) ::
    :ok
  @doc """
  Obliterates a NetworkConnection. Use with caution.
  """
  defdelegate delete(nc),
    to: NetworkInternal.Connection
end
