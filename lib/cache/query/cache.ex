defmodule Helix.Cache.Query.Cache do
  @moduledoc """
  Inter-domain Cache Query API.

  Lookups are transparent to cache misses, meaning that they will automatically
  populate the cache and then reply with the requested data.

  Failure can happen when the original data cannot be built (wrong id,
  invalid data etc)
  """

  alias Helix.Entity.Model.Entity
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.Storage
  alias Helix.Cache.Internal.Cache, as: CacheInternal

  @doc """
  Given a server, return the entire row, cached or not.
  """
  def from_server_get_all(%Server{server_id: id}),
    do: from_server_get_all(to_string(id))
  def from_server_get_all(id = %Server.ID{}),
    do: from_server_get_all(to_string(id))
  def from_server_get_all(server_id) do
    CacheInternal.lookup(:server, {server_id})
  end

  @spec from_server_get_nips(Server.id) ::
    {:ok, [Network.nip]}
    | {:error, {:server, :notfound}}
    | {:error, :unknown}
  @doc """
  Given a server, return the nips (network_id, ip) linked to it.
  """
  def from_server_get_nips(%Server{server_id: id}),
    do: from_server_get_nips(to_string(id))
  def from_server_get_nips(id = %Server.ID{}),
    do: from_server_get_nips(to_string(id))
  def from_server_get_nips(server_id) do
    CacheInternal.lookup({:server, :nips}, {server_id})
  end

  @doc """
  Given a server, return the storages linked to it.
  """
  def from_server_get_storages(%Server{server_id: id}),
    do: from_server_get_storages(to_string(id))
  def from_server_get_storages(id = %Server.ID{}),
    do: from_server_get_storages(to_string(id))
  def from_server_get_storages(server_id) do
    CacheInternal.lookup({:server, :storages}, {server_id})
  end

  @doc """
  Given a server, return its hardware resources.
  """
  def from_server_get_resources(%Server{server_id: id}),
    do: from_server_get_resources(to_string(id))
  def from_server_get_resources(id = %Server.ID{}),
    do: from_server_get_resources(to_string(id))
  def from_server_get_resources(server_id) do
    CacheInternal.lookup({:server, :resources}, {server_id})
  end

  @doc """
  Given a server, return components linked to its motherboard.
  Note: it does not include the motherboard.
  """
  def from_server_get_components(%Server{server_id: id}),
    do: from_server_get_components(to_string(id))
  def from_server_get_components(id = %Server.ID{}),
    do: from_server_get_components(to_string(id))
  def from_server_get_components(server_id) do
    CacheInternal.lookup({:server, :components}, {server_id})
  end

  @doc """
  Given a motherboard, return its entire server row.
  """
  def from_motherboard_get_all(%Motherboard{motherboard_id: id}),
    do: from_motherboard_get_all(to_string(id))
  def from_motherboard_get_all(id = %Component.ID{}),
    do: from_motherboard_get_all(to_string(id))
  def from_motherboard_get_all(motherboard_id) do
    CacheInternal.lookup(:motherboard, {motherboard_id})
  end

  @doc """
  Given a motherboard, return its owner (entity).
  """
  def from_motherboard_get_entity(%Motherboard{motherboard_id: id}),
    do: from_motherboard_get_entity(to_string(id))
  def from_motherboard_get_entity(id = %Component.ID{}),
    do: from_motherboard_get_entity(to_string(id))
  def from_motherboard_get_entity(motherboard_id) do
    CacheInternal.lookup({:motherboard, :entity}, {motherboard_id})
  end

  @doc """
  Given a motherboard, return its total resources.
  """
  def from_motherboard_get_resources(%Motherboard{motherboard_id: id}),
    do: from_motherboard_get_resources(to_string(id))
  def from_motherboard_get_resources(id = %Component.ID{}),
    do: from_motherboard_get_resources(to_string(id))
  def from_motherboard_get_resources(motherboard_id) do
    CacheInternal.lookup({:motherboard, :resources}, {motherboard_id})
  end

  @doc """
  Given a motherboard, return the components linked to it.
  """
  def from_motherboard_get_components(%Motherboard{motherboard_id: id}),
    do: from_motherboard_get_components(to_string(id))
  def from_motherboard_get_components(id = %Component.ID{}),
    do: from_motherboard_get_components(to_string(id))
  def from_motherboard_get_components(motherboard_id) do
    CacheInternal.lookup({:motherboard, :components}, {motherboard_id})
  end

  @doc """
  Given an entity, return its motherboard.
  """
  def from_entity_get_motherboard(%Entity{entity_id: id}),
    do: from_entity_get_motherboard(to_string(id))
  def from_entity_get_motherboard(id = %Entity.ID{}),
    do: from_entity_get_motherboard(to_string(id))
  def from_entity_get_motherboard(entity_id) do
    CacheInternal.lookup({:entity, :motherboard}, {entity_id})
  end

  @doc """
  Given a storage, return its server.
  """
  def from_storage_get_server(%Storage{storage_id: id}),
    do: from_storage_get_server(to_string(id))
  def from_storage_get_server(id = %Storage.ID{}),
    do: from_storage_get_server(to_string(id))
  def from_storage_get_server(storage_id) do
    CacheInternal.lookup({:storage, :server}, {storage_id})
  end

  @doc """
  Given a nip, return its server.
  """
  def from_nip_get_server(id = %Network.ID{}, ip),
    do: from_nip_get_server(to_string(id), ip)
  def from_nip_get_server(network_id, ip) do
    CacheInternal.lookup({:nip, :server}, {network_id, ip})
  end

  @doc """
  Given a component, return its motherboard. Returns nil if it isn't attached.
  """
  def from_component_get_motherboard(%Component{component_id: id}),
    do: from_component_get_motherboard(to_string(id))
  def from_component_get_motherboard(id = %Component.ID{}),
    do: from_component_get_motherboard(to_string(id))
  def from_component_get_motherboard(component_id) do
    CacheInternal.lookup({:component, :motherboard}, {component_id})
  end
end
