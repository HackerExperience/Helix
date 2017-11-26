defmodule Helix.Network.Action.Network.Connection do

  alias Helix.Server.Model.Component
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Network.Internal.Network, as: NetworkInternal

  @spec create(Network.idt, Network.ip, Entity.idt, Component.idt | nil) ::
    {:ok, Network.Connection.t}
    | {:error, :internal}
  def create(network, ip, entity, nic \\ nil) do
    case NetworkInternal.Connection.create(network, ip, entity, nic) do
      {:ok, nc} ->
        {:ok, nc}

      {:error, _} ->
        {:error, :internal}
    end
  end

  def update_ip(nc = %Network.Connection{}, new_ip) do
    case NetworkInternal.Connection.update_ip(nc, new_ip) do
      {:ok, nc} ->
        {:ok, nc}

      {:error, _} ->
        {:error, :internal}
    end
  end

  def update_nic(nc = %Network.Connection{}, new_nic) do
    case NetworkInternal.Connection.update_ip(nc, new_nic) do
      {:ok, nc} ->
        {:ok, nc}

      {:error, _} ->
        {:error, :internal}
    end
  end

  def delete(nc = %Network.Connection{}) do
    NetworkInternal.Connection.delete(nc)
  end
end
