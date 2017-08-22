defmodule Helix.Cache.Internal.Builder do

  @moduledoc """
  CacheBuilder has the role of figuring out the actual data by directly
  querying the services who own such data.

  It is an exception within our architecture, since it is allowed to access
  each service's Internal modules. Because of this, some care must be taken
  to ensure the Internal method itself won't use, directly or indirectly, the
  cache service. Otherwise, a nasty infinite loop could happen.

  These functions are quite expensive in the sense that they may have to query
  several different services in order to compile a denormalized cache. And,
  that's the reason Cache exists.
  """

  alias HELL.IPv4
  alias Helix.Entity.Internal.Entity, as: EntityInternal
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Hardware.Internal.Component, as: ComponentInternal
  alias Helix.Hardware.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Server.Model.Server
  alias Helix.Software.Internal.Storage, as: StorageInternal
  alias Helix.Software.Model.Storage
  alias Helix.Universe.NPC.Internal.NPC, as: NPCInternal
  alias Helix.Universe.NPC.Internal.Web, as: NPCWebInternal
  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Cache.Model.ComponentCache
  alias Helix.Cache.Model.NetworkCache
  alias Helix.Cache.Model.ServerCache
  alias Helix.Cache.Model.StorageCache
  alias Helix.Cache.Model.WebCache

  @spec by_server(Server.id) ::
    {:ok, ServerCache.t}
    | {:error, {:server, :notfound}}
    | {:error, :internal}
  def by_server(server_id) do
    with \
      entity = %{} <- EntityInternal.fetch_by_server(server_id) || :nxserver,
      server = %{} <- ServerInternal.fetch(server_id) || :nxserver,
      true <- not is_nil(server.motherboard_id) || {:nxmobo, entity},
      mobo_component = %{} <- ComponentInternal.fetch(server.motherboard_id),
      motherboard = %{} <- MotherboardInternal.fetch(mobo_component),
      resources = %{} <- MotherboardInternal.resources(motherboard),
      components = MotherboardInternal.get_components_ids(motherboard),
      storages = get_storages_from_motherboard(motherboard),
      networks = get_networks_from_motherboard(motherboard)
    do
      sp = ServerCache.new(
        {server_id, entity.entity_id, server.motherboard_id, networks, storages,
         resources, components})
      {:ok, sp}
    else
      :nxserver ->
        {:error, {:server, :notfound}}
      {:nxmobo, entity} ->
        {:ok, ServerCache.new(server_id, entity.entity_id)}
      _ ->
        {:error, :internal}
    end
  end

  @spec by_motherboard(Motherboard.id) ::
    {:ok, ServerCache.t}
    | {:error, {:motherboard, :notfound}}
    | {:error, {:server, :notfound}}
    | {:error, :internal}
  def by_motherboard(motherboard_id) do
    with \
      server =
        %{} <- ServerInternal.fetch_by_motherboard(motherboard_id) || :nxmobo
    do
      by_server(server.server_id)
    else
      :nxmobo ->
        {:error, {:motherboard, :notfound}}
    end
  end

  @spec by_nip(Network.id, IPv4.t) ::
    {:ok, NetworkCache.t}
    | {:error, {:nip, :notfound}}
    | {:error, {:server, :notfound}}
  def by_nip(network_id, ip) do
    with \
      mobo = %{} <- MotherboardInternal.fetch_by_nip(network_id, ip) || :nxnip,
      server = %{} <- ServerInternal.fetch_by_motherboard(mobo) || :nxserver
    do
      {:ok, NetworkCache.new(network_id, ip, server.server_id)}
    else
      :nxnip ->
        {:error, {:nip, :notfound}}
      :nxserver ->
        {:error, {:server, :notfound}}
    end

  end

  @spec by_storage(Storage.id) ::
    {:ok, StorageCache.t}
    | {:error, {:storage, :notfound}}
    | {:error, {:drive, :notfound}}
    | {:error, {:drive, :unlinked}}
    | {:error, :internal}
  def by_storage(storage_id) do
    with \
      storage = %{} <- StorageInternal.fetch(storage_id) || :nxstorage,
      drives = get_drives_from_storage(storage),
      false <- Enum.empty?(drives) && :nxdrive,
      drive_id = List.first(drives),
      motherboard_id = ComponentInternal.get_motherboard_id(drive_id),
      true <- not is_nil(motherboard_id) || :unlinked,
      server = %{} <- ServerInternal.fetch_by_motherboard(motherboard_id)
    do
      {:ok, StorageCache.new(storage_id, server.server_id)}
    else
      :nxstorage ->
        {:error, {:storage, :notfound}}
      :nxdrive ->
        {:error, {:drive, :notfound}}
      :unlinked ->
        {:error, {:drive, :unlinked}}
      _ ->
        {:error, :internal}
    end
  end

  @spec by_component(Component.id) ::
    {:ok, ComponentCache.t}
    | {:error, {:component, :notfound}}
  def by_component(component_id) do
    with \
      mobo_id = ComponentInternal.get_motherboard_id(component_id),
      true <- not is_nil(mobo_id) || :nxmobo,
      %{} <- ServerInternal.fetch_by_motherboard(mobo_id) || :unlinked
    do
      {:ok, ComponentCache.new(component_id, mobo_id)}
    else
      :nxmobo ->
        {:error, {:component, :notfound}}
      :unlinked ->
        {:error, {:component, :unlinked}}
    end
  end

  @spec web_by_nip(Network.id, IPv4.t) ::
    {:ok, WebCache.t}
    | {:error, {:nip, :notfound}}
    | {:error, {:server, :notfound}}
    | {:error, {:web, :notfound}}
    | {:error, :internal}
  def web_by_nip(network_id, ip) do
    with \
      mobo = %{} <- MotherboardInternal.fetch_by_nip(network_id, ip) || :nxnip,
      server = %{} <- ServerInternal.fetch_by_motherboard(mobo) || :nxserver,
      entity = %{} <- EntityInternal.fetch_by_server(server),
      content = %{} <- get_web_content(entity, network_id, ip) || :nxweb
    do
      {:ok, WebCache.new(network_id, ip, content)}
    else
      :nxnip ->
        {:error, {:nip, :notfound}}
      :nxserver ->
        {:error, {:server, :notfound}}
      :nxweb ->
        {:error, {:web, :notfound}}
      _ ->
        {:error, :internal}
      end
  end

  @spec get_web_content(Entity.t, Network.id, IPv4.t) ::
    NPCWebInternal.npc_content
    | nil
  defp get_web_content(entity, network_id, ip) do
    case entity.entity_type do
      :npc ->
        NPC.ID.cast!(to_string(entity.entity_id))
        |> NPCInternal.fetch()
        |> NPCWebInternal.generate_content(network_id, ip)
      :account ->
        %{}
    end
  end

  @spec get_storages_from_motherboard(Motherboard.t) ::
    [Storage.id]
  defp get_storages_from_motherboard(motherboard) do
    storages = motherboard
      |> MotherboardInternal.get_hdds()
      |> Enum.map(&StorageInternal.fetch_by_hdd(&1.hdd_id))

    Enum.reduce(storages, [], fn(storage, acc) ->
      storage
      && [storage.storage_id] ++ acc
      || acc
    end)
  end

  @spec get_networks_from_motherboard(Motherboard.t) ::
    [%{network_id: Network.id, ip: IPv4.t}]
  defp get_networks_from_motherboard(motherboard) do
    motherboard
    |> MotherboardInternal.get_networks()
    |> Enum.reduce([], fn(nip, acc) ->
      nip
      && [%{network_id: nip.network_id, ip: nip.ip}] ++ acc
      || acc
    end)
  end

  @spec get_drives_from_storage(Storage.t) ::
    [Component.id]
  defp get_drives_from_storage(storage) do
    storage
    |> StorageInternal.get_drives()
    |> Enum.map(&(&1.drive_id))
  end
end
