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
  alias Helix.Network.Internal.Network, as: NetworkInternal
  alias Helix.Network.Model.Network
  alias Helix.Server.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Motherboard
  alias Helix.Server.Model.Server
  alias Helix.Software.Internal.Storage, as: StorageInternal
  alias Helix.Software.Model.Storage
  alias Helix.Universe.NPC.Internal.NPC, as: NPCInternal
  alias Helix.Universe.NPC.Internal.Web, as: NPCWebInternal
  alias Helix.Universe.NPC.Model.NPC
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
      server = %{} <- ServerInternal.fetch(server_id) || :nxserver,
      true <- not is_nil(server.motherboard_id) || :nxmobo,
      motherboard = %{} <- MotherboardInternal.fetch(server.motherboard_id),
      storages = get_storages_from_motherboard(motherboard),
      networks = get_networks_from_motherboard(motherboard)
    do
      sp = ServerCache.new(server_id, networks, storages)
      {:ok, sp}
    else
      :nxserver ->
        {:error, {:server, :notfound}}
      :nxmobo ->
        {:ok, ServerCache.new(server_id)}
      _ ->
        {:error, :internal}
    end
  end

  @spec by_nip(Network.id, IPv4.t) ::
    {:ok, NetworkCache.t}
    | {:error, {:nip, :notfound}}
    | {:error, {:server, :notfound}}
    | {:error, :internal}
  def by_nip(network_id, ip) do
    with \
      nc = %{} <- NetworkInternal.Connection.fetch(network_id, ip) || :nxnip,
      motherboard = %{} <- MotherboardInternal.fetch_by_component(nc.nic_id),
      server = %{} <-
        ServerInternal.fetch_by_motherboard(motherboard) || :nxserver
    do
      {:ok, NetworkCache.new(network_id, ip, server.server_id)}
    else
      :nxnip ->
        {:error, {:nip, :notfound}}

      :nxserver ->
        {:error, {:server, :notfound}}

      _ ->
        {:error, :internal}
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
      motherboard = MotherboardInternal.fetch_by_component(drive_id),
      true <- not is_nil(motherboard) || :unlinked,
      server = %{} <- ServerInternal.fetch_by_motherboard(motherboard)
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

  @spec web_by_nip(Network.id, IPv4.t) ::
    {:ok, WebCache.t}
    | {:error, {:nip, :notfound}}
    | {:error, {:server, :notfound}}
    | {:error, {:web, :notfound}}
    | {:error, :internal}
  def web_by_nip(network_id, ip) do
    with \
      nc = %{} <- NetworkInternal.Connection.fetch(network_id, ip) || :nxnip,
      motherboard = %{} <- MotherboardInternal.fetch_by_component(nc.nic_id),
      server = %{} <-
         ServerInternal.fetch_by_motherboard(motherboard) || :nxserver,
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
        entity.entity_id
        |> to_string()
        |> NPC.ID.cast!()
        |> NPCInternal.fetch()
        |> NPCWebInternal.generate_content(network_id, ip)

      :account ->
        %{}
    end
  end

  @spec get_storages_from_motherboard(Motherboard.t) ::
    [Storage.id]
  defp get_storages_from_motherboard(motherboard) do
    storages =
      motherboard
      |> MotherboardInternal.get_hdds()
      |> Enum.map(&StorageInternal.fetch_by_hdd(&1.component_id))

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
    |> MotherboardInternal.get_nics()
    |> Enum.reduce([], fn nic, acc ->
      nc = NetworkInternal.Connection.fetch_by_nic(nic)

      nc
      && acc ++ [%{network_id: nc.network_id, ip: nc.ip}]
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
