defmodule Helix.Cache.Query.Cache do
  @moduledoc """
  Inter-domain Cache Query API.

  Lookups are transparent to cache misses, meaning that they will automatically
  populate the cache and then reply with the requested data.

  Failure can happen when the original data cannot be built (wrong id,
  invalid data etc)
  """

  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.Storage
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Model.ServerCache
  alias Helix.Cache.Model.WebCache

  @spec from_server_get_all(Server.idtb) ::
    {:ok, ServerCache.t}
    | {:error, {:server, :notfound}}
    | {:error, :internal}
  @doc """
  Given a server, return the entire row, cached or not.
  """
  def from_server_get_all(server),
    do: CacheInternal.lookup(:server, {server_to_id(server)})

  @spec from_server_get_nips(Server.id) ::
    {:ok, [Network.nip]}
    | {:error, {:server, :notfound}}
    | {:error, :internal}
  @doc """
  Given a server, return the nips (network_id, ip) linked to it.
  """
  def from_server_get_nips(server),
    do: CacheInternal.lookup({:server, :nips}, {server_to_id(server)})

  @spec from_server_get_storages(Server.idtb) ::
    {:ok, [Storage.id]}
    | {:error, {:server, :notfound}}
    | {:error, :internal}
  @doc """
  Given a server, return the storages linked to it.
  """
  def from_server_get_storages(server),
    do: CacheInternal.lookup({:server, :storages}, {server_to_id(server)})

  @spec from_server_get_resources(Server.idtb) ::
    {:ok, term}
    | {:error, {:server, :notfound}}
    | {:error, :internal}
  @doc """
  Given a server, return its hardware resources.
  """
  def from_server_get_resources(server),
    do: CacheInternal.lookup({:server, :resources}, {server_to_id(server)})

  @spec from_server_get_components(Server.idtb) ::
    {:ok, [Component.id]}
    | {:error, {:server, :notfound}}
    | {:error, :internal}
  @doc """
  Given a server, return components linked to its motherboard.
  Note: it does not include the motherboard.
  """
  def from_server_get_components(server),
    do: CacheInternal.lookup({:server, :components}, {server_to_id(server)})

  @spec from_motherboard_get_all(Motherboard.t | Component.idtb) ::
    {:ok, ServerCache.t}
    | {:error, {:server, :notfound}}
    | {:error, {:motherboard, :notfound}}
    | {:error, :internal}
  @doc """
  Given a motherboard, return its entire server row.
  """
  def from_motherboard_get_all(motherboard),
    do: CacheInternal.lookup(:motherboard, {motherboard_to_id(motherboard)})

  @spec from_motherboard_get_entity(Motherboard.idtb) ::
    {:ok, Entity.id}
    | {:error, {:server, :notfound}}
    | {:error, {:motherboard, :notfound}}
    | {:error, :internal}
  @doc """
  Given a motherboard, return its owner (entity).
  """
  def from_motherboard_get_entity(motherboard) do
    id = motherboard_to_id(motherboard)
    CacheInternal.lookup({:motherboard, :entity}, {id})
  end

  @spec from_motherboard_get_resources(Motherboard.idtb) ::
    {:ok, term}
    | {:error, {:server, :notfound}}
    | {:error, {:motherboard, :notfound}}
    | {:error, :internal}
  @doc """
  Given a motherboard, return its total resources.
  """
  def from_motherboard_get_resources(motherboard) do
    id = motherboard_to_id(motherboard)
    CacheInternal.lookup({:motherboard, :resources}, {id})
  end

  @spec from_motherboard_get_components(Motherboard.idtb) ::
    {:ok, [Component.id]}
    | {:error, {:server, :notfound}}
    | {:error, {:motherboard, :notfound}}
    | {:error, :internal}
  @doc """
  Given a motherboard, return the components linked to it.
  """
  def from_motherboard_get_components(motherboard) do
    id = motherboard_to_id(motherboard)
    CacheInternal.lookup({:motherboard, :components}, {id})
  end

  @spec from_entity_get_motherboard(Entity.idtb) ::
    {:ok, Motherboard.id}
    | {:error, {:server, :notfound}}
    | {:error, {:motherboard, :notfound}}
    | {:error, {:server, :notfound}}
    | {:error, :internal}
  @doc """
  Given an entity, return its motherboard.
  """
  def from_entity_get_motherboard(entity),
    do: CacheInternal.lookup({:entity, :motherboard}, {entity_to_id(entity)})

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

  @spec from_nip_get_web(Network.idtb, IPv4.t) ::
    {:ok, WebCache.t}
    | {:error, {:nip, :notfound}}
    | {:error, {:server, :notfound}}
    | {:error, {:web, :notfound}}
  def from_nip_get_web(network, ip) do
    network_id = network_to_id(network)
    CacheInternal.lookup({:web, :content}, {network_id, ip})
  end

  @spec from_component_get_motherboard(Component.idtb) ::
    {:ok, Motherboard.id}
    | {:error, {:component, :notfound}}
    | {:error, {:component, :unlinked}}
  @doc """
  Given a component, return its motherboard. Returns nil if it isn't attached.
  """
  def from_component_get_motherboard(component) do
    id = component_to_id(component)
    CacheInternal.lookup({:component, :motherboard}, {id})
  end

  @spec entity_to_id(Entity.idtb) ::
    HELL.PK.t
  def entity_to_id(%Entity{entity_id: id}),
    do: entity_to_id(id)
  def entity_to_id(id = %Entity.ID{}),
    do: to_string(id)
  def entity_to_id(id) when is_binary(id),
    do: id

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

  @spec motherboard_to_id(Motherboard.t | Component.idtb) ::
    HELL.PK.t
  defp motherboard_to_id(%Motherboard{motherboard_id: id}),
    do: component_to_id(id)
  defp motherboard_to_id(%Component{component_id: id, component_type: :mobo}),
    do: to_string(id)
  defp motherboard_to_id(id = %Component.ID{}),
    do: to_string(id)
  defp motherboard_to_id(id) when is_binary(id),
    do: id

  @spec component_to_id(Component.idtb) ::
    HELL.PK.t
  defp component_to_id(%Component{component_id: id}),
    do: component_to_id(id)
  defp component_to_id(id = %Component.ID{}),
    do: to_string(id)
  defp component_to_id(id) when is_binary(id),
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
