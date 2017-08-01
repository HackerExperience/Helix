defmodule Helix.Cache.Internal.Builder do

  @moduledoc """
  CacheBuilder has the role of figuring out the actual data by directly
  querying the services who own such data.

  It is an exception within our architecture, since it is allowed to access
  each service's Internal modules. Because of this, some care must be taken
  to ensure the Internal method itself won't use, directly or indirectly, the
  cache service. Otherwise, a nasty infinite loop could happen.
  """

  alias HELL.IPv4
  alias Helix.Entity.Internal.Entity, as: EntityInternal
  alias Helix.Network.Model.Network
  alias Helix.Hardware.Internal.Component, as: ComponentInternal
  alias Helix.Hardware.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Server.Model.Server
  alias Helix.Software.Internal.Storage, as: StorageInternal
  alias Helix.Software.Model.Storage
  alias Helix.Cache.Model.Populate.Component, as: ComponentParams
  alias Helix.Cache.Model.Populate.Network, as: NetworkParams
  alias Helix.Cache.Model.Populate.Server, as: ServerParams
  alias Helix.Cache.Model.Populate.Storage, as: StorageParams

  @spec by_server(Server.id) ::
    {:ok, ServerParams.t}
    | {:error, {:server, :notfound}}
    | {:error, :unknown}
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
      sp = ServerParams.new(
        {server_id, entity.entity_id, server.motherboard_id, networks, storages,
         resources, components})
      {:ok, sp}
    else
      :nxserver ->
        {:error, {:server, :notfound}}
      {:nxmobo, entity} ->
        {:ok, ServerParams.new(server_id, entity.entity_id)}
      _ ->
        {:error, :unknown}
    end
  end

  @spec by_motherboard(Motherboard.id) ::
    {:ok, ServerParams.t}
    | {:error, {:server, :notfound}}
    | {:error, {:motherboard, :notfound}}
    | {:error, :unknown}
  def by_motherboard(motherboard_id) do
    with \
      server =
        %{} <- ServerInternal.fetch_by_motherboard(motherboard_id) || :nxmobo
    do
      by_server(server.server_id)
    else
      :nxmobo ->
        {:error, {:motherboard, :notfound}}
      _ ->
        {:error, :unknown}
    end
  end

  # @spec by_nip(Network.id, IPv4.t) ::
  #   {:ok, NetworkParams.t}
  #   | {:error, {:nip, :notfound}}
  #   | {:error, {:server, :notfound}}
  #   | {:error, :unknown}
  def by_nip(network_id, ip) do
    with \
      mobo = %{} <- MotherboardInternal.fetch_by_nip(network_id, ip) || :nxnip,
      server = %{} <- ServerInternal.fetch_by_motherboard(mobo) || :nxserver
    do
      {:ok, NetworkParams.new(network_id, ip, server.server_id)}
    else
      :nxnip ->
        {:error, {:nip, :notfound}}
      :nxserver ->
        {:error, {:server, :notfound}}
      _ ->
        {:error, :unknown}
    end

  end

  @spec by_storage(Storage.id) ::
    {:ok, StorageParams.t}
    | {:error, {:storage, :notfound}}
    | {:error, {:motherboard, :unlinked}}
    | {:error, :unknown}
  def by_storage(storage_id) do
    with \
      storage = %{} <- StorageInternal.fetch(storage_id) || :nxstorage,
      [drive_id|_] = get_drives_from_storage(storage),
      motherboard_id = ComponentInternal.get_motherboard_id(drive_id),
      true <- not is_nil(motherboard_id) || :unlinked,
      server = %{} <- ServerInternal.fetch_by_motherboard(motherboard_id)
    do
      {:ok, StorageParams.new(storage_id, server.server_id)}
    else
      :nxstorage ->
        {:error, {:storage, :notfound}}
      :unlinked ->
        {:error, {:motherboard, :unlinked}}
      _ ->
        {:error, :unknown}
    end
  end

  @spec by_component(Component.id) ::
    {:ok, ComponentParams.t}
    | {:error, {:component, :notfound}}
  def by_component(component_id) do
    case ComponentInternal.get_motherboard_id(component_id) do
      nil ->
        {:error, {:component, :notfound}}
      motherboard_id ->
        {:ok, ComponentParams.new(component_id, motherboard_id)}
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
