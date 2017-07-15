defmodule Helix.Cache.Internal.Purge do
  @moduledoc """
  `PurgeInternal` is responsible for handling cache invalidation.

  Currently, the approach we take is to simply delete all related entries to
  whatever is being invalidated. It's possible to take a more smart (albeit
  complex) approach and update only whatever field/data has been purged,
  however that complexity isn't desirable right now.
  """

  alias Helix.Server.Model.Server
  alias Helix.Software.Model.Storage
  alias Helix.Hardware.Model.Component
  alias Helix.Network.Model.Network
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Model.ComponentCache
  alias Helix.Cache.Model.ServerCache
  alias Helix.Cache.Model.StorageCache
  alias Helix.Cache.Model.NetworkCache
  alias Helix.Cache.Repo

  import HELL.MacroHelpers

  @spec purge(:server, Server.id) :: no_return
  @spec purge(:component, Component.id) :: no_return
  @spec purge(:storage, Storage.id) :: no_return
  @spec purge(:network, Network.id) :: no_return
  @doc """
  `purge/2` and `purge/3` are the public interface of `PurgeInternal`.

  If the requested entry to be purged exists, it removes it according to
  the purge logic defined at `purge_logic/2` and `purge_logic/3`.

  It performs a no-op if the requested entry isn't cached.
  """
  def purge(:server, server_id) do
    case CacheInternal.direct_query(:server, server_id) do
      {:hit, server} ->
        purge_logic(:server, server)
        :ok
      :miss ->
        :nocache
    end
  end
  def purge(:component, component_id) do
    case CacheInternal.direct_query(:component, component_id) do
      {:hit, component} ->
        purge_logic(:component, component)
        :ok
      :miss ->
        :nocache
    end
  end
  def purge(:storage, storage_id) do
    case CacheInternal.direct_query(:storage, storage_id) do
      {:hit, storage} ->
        purge_logic(:storage, storage)
        :ok
      :miss ->
        :nocache
    end
  end
  def purge(:network, network_id, ip) do
    case CacheInternal.direct_query(:network, [network_id, ip]) do
      {:hit, network} ->
        purge_logic(:network, network)
        :ok
      :miss ->
        :nocache
    end
  end

  @spec purge_logic(:server, ServerCache.t) :: no_return
  @spec purge_logic(:component, ComponentCache.t) :: no_return
  @spec purge_logic(:storage, StorageCache.t) :: no_return
  @spec purge_logic(:Network, NetworkCache.t) :: no_return
  docp """
  `purge_logic/2` and `purge_logic/3` defines how we deal with Computer
  Science's second hardest problem: cache invalidation.

  As described on the module doc, our current approach is as dumb as it can be:
  delete everything. As long as it works in production, we won't change it.
  """
  defp purge_logic(:server, server) do
    delete(:server, server.server_id)

    Enum.each(server.components, fn(component_id) ->
      delete(:component, component_id)
    end)

    Enum.each(server.storages, fn(storage_id) ->
      delete(:storage, storage_id)
    end)

    Enum.each(server.networks, fn(network) ->
      delete(:network, network["network_id"], network["ip"])
    end)
  end
  defp purge_logic(:component, component) do
    delete(:component, component.component_id)

    motherboard_id = component.motherboard_id
    query =
      CacheInternal.direct_query({:server, :by_motherboard}, motherboard_id)

    case query do
      {:hit, server} ->
        purge_logic(:server, server)
      :miss ->
        :ok
    end
  end
  defp purge_logic(:storage, storage) do
    delete(:storage, storage.storage_id)

    case CacheInternal.direct_query(:server, storage.server_id) do
      {:hit, server} ->
        purge_logic(:server, server)
      :miss ->
        :ok
    end
  end
  defp purge_logic(:network, network) do
    delete(:network, network.network_id, network.ip)

    case CacheInternal.direct_query(:server, network.server_id) do
      {:hit, server} ->
        purge_logic(:server, server)
      :miss ->
        :ok
    end
  end

  @spec delete(:server, Server.id) :: no_return
  @spec delete(:component, Component.id) :: no_return
  @spec delete(:storage, Storage.id) :: no_return
  @spec delete(:network, Network.id, HELL.IPv4.t) :: no_return
  defp delete(:server, server_id) do
    ServerCache.Query.by_server(server_id)
    |> Repo.delete_all()
  end
  defp delete(:component, component_id) do
    ComponentCache.Query.by_component(component_id)
    |> Repo.delete_all()
  end
  defp delete(:storage, storage_id) do
    StorageCache.Query.by_storage(storage_id)
    |> Repo.delete_all()
  end
  defp delete(:network, network_id, ip) do
    NetworkCache.Query.by_nip(network_id, ip)
    |> Repo.delete_all()
  end
end
