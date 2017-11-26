defmodule Helix.Cache.Query.Cache do
  @moduledoc """
  Inter-domain Cache Query API.

  Lookups are transparent to cache misses, meaning that they will automatically
  populate the cache and then reply with the requested data.

  Failure can happen when the original data cannot be built (wrong id,
  invalid data etc)
  """

  import HELL.Macros

  alias HELL.IPv4
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.Storage
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Model.ServerCache
  alias Helix.Cache.Model.WebCache

  raisable {:from_server_get_all, 1}
  @spec from_server_get_all(Server.idtb) ::
    {:ok, ServerCache.t}
    | {:error, {:server, :notfound}}
    | {:error, :internal}
  @doc """
  Given a server, return the entire row, cached or not.
  """
  def from_server_get_all(server),
    do: CacheInternal.lookup(:server, {server_to_id(server)})

  raisable {:from_server_get_nips, 1}
  @spec from_server_get_nips(Server.id) ::
    {:ok, [Network.nip]}
    | {:error, {:server, :notfound}}
    | {:error, :internal}
  @doc """
  Given a server, return the nips (network_id, ip) linked to it.
  """
  def from_server_get_nips(server),
    do: CacheInternal.lookup({:server, :nips}, {server_to_id(server)})

  raisable {:from_server_get_storages, 1}
  @spec from_server_get_storages(Server.idtb) ::
    {:ok, [Storage.id]}
    | {:error, {:server, :notfound}}
    | {:error, :internal}
  @doc """
  Given a server, return the storages linked to it.
  """
  def from_server_get_storages(server),
    do: CacheInternal.lookup({:server, :storages}, {server_to_id(server)})

  raisable {:from_storage_get_server, 1}
  @spec from_storage_get_server(Storage.idtb) ::
    {:ok, Server.id}
    | {:error, {:storage, :notfound}}
    | {:error, {:drive, :notfound}}
    | {:error, {:drive, :unlinked}}
    | {:error, :internal}
  @doc """
  Given a storage, return its server.
  """
  def from_storage_get_server(storage),
    do: CacheInternal.lookup({:storage, :server}, {storage_to_id(storage)})

  raisable {:from_nip_get_server, 2}
  @spec from_nip_get_server(Network.idtb, IPv4.t) ::
    {:ok, Server.id}
    | {:error, {:nip, :notfound}}
    | {:error, {:server, :notfound}}
    | {:error, :internal}
  @doc """
  Given a nip, return its server.
  """
  def from_nip_get_server(network, ip) do
    network_id = network_to_id(network)
    CacheInternal.lookup({:network, :server}, {network_id, ip})
  end

  raisable {:from_nip_get_web, 2}
  @spec from_nip_get_web(Network.idtb, IPv4.t) ::
    {:ok, WebCache.t}
    | {:error, {:nip, :notfound}}
    | {:error, {:server, :notfound}}
    | {:error, {:web, :notfound}}
  def from_nip_get_web(network, ip) do
    network_id = network_to_id(network)
    CacheInternal.lookup({:web, :content}, {network_id, ip})
  end

  @spec storage_to_id(Storage.idtb) ::
    HELL.PK.t
  def storage_to_id(%Storage{storage_id: id}),
    do: storage_to_id(id)
  def storage_to_id(id = %Storage.ID{}),
    do: to_string(id)
  def storage_to_id(id) when is_binary(id),
    do: id

  @spec network_to_id(Network.idtb) ::
    HELL.PK.t
  def network_to_id(%Network{network_id: id}),
    do: network_to_id(id)
  def network_to_id(id = %Network.ID{}),
    do: to_string(id)
  def network_to_id(id) when is_binary(id),
    do: id

  @spec server_to_id(Server.idtb) ::
    HELL.PK.t
  defp server_to_id(%Server{server_id: id}),
    do: server_to_id(id)
  defp server_to_id(id = %Server.ID{}),
    do: to_string(id)
  defp server_to_id(id) when is_binary(id),
    do: id
end
