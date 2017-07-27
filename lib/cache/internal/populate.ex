defmodule Helix.Cache.Internal.Populate do
  @moduledoc """
  `Populate` is responsible for, well, populating the cache.

  In order to gather the "actual" data, it uses other services' Query modules.
  Since these services *own* that data, Cache can trust it is accurate.

  `Populate` is called dynamically by `Helix.Cache.Internal.Cache` every time
  a "miss" happens, i.e. the requested data was not cached. It then proceeds
  to figure out what the current data is (using `populate`), caching it.

  It is designed in such a way to have independent data models, each with their
  own logic for populating the cache database.
  """

  import HELL.MacroHelpers

  alias Helix.Cache.Repo
  alias Helix.Cache.Model.ServerCache
  alias Helix.Cache.Model.NetworkCache
  alias Helix.Cache.Model.StorageCache
  alias Helix.Cache.Model.ComponentCache
  alias Helix.Cache.Model.Populate.Server, as: ServerParams
  alias Helix.Cache.Model.Populate.Network, as: NetworkParams
  alias Helix.Cache.Model.Populate.Component, as: ComponentParams
  alias Helix.Cache.Model.Populate.Storage, as: StorageParams
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue
  alias Helix.Cache.Internal.Builder, as: BuilderInternal

  @doc """
  Populates the corresponding model, based on its primary key.

  These functions are quite expensive in the sense that they may have to query
  several different services in order to compile a denormalized cache.
  """
  def populate(:server, server_id) do
    case BuilderInternal.by_server(server_id) do
      {:ok, params} ->
        cache(params)
      error ->
        error
    end
  end
  def populate(:storage, storage_id) do
    case BuilderInternal.by_storage(storage_id) do
      {:ok, params} ->
        cache(params)
      error ->
        error
    end
  end
  def populate(:component, component_id) do
    case BuilderInternal.by_component(component_id) do
      {:ok, params} ->
        cache(params)
      error ->
        error
    end
  end
  def populate(:network, network_id, ip) do
    case BuilderInternal.by_nip(network_id, ip) do
      {:ok, params} ->
        cache(params)
      error ->
        error
    end
  end

  docp """
  Coordinates the process of purging and adding cached data to the DB.

  Purging here is required because adding to the DB is asynchronous. This means
  that, if another query comes along while the data is still being populated,
  we won't serve invalid data.
  """
  defp cache(params = %ServerParams{}) do
    if not is_nil(params.motherboard_id) do

      # Mark all related objects as purged
      purge_list = [
        {:server, [params.server_id]},
        {:component, [params.motherboard_id]}
      ]
      networks_purge = Enum.map(params.networks,
        &({:network, [&1.network_id, &1.ip]}))
      components_purge = Enum.map(params.components, &({:component, [&1]}))
      storages_purge = Enum.map(params.storages, &({:storage, [&1]}))

      purge_list
      |> Kernel.++(networks_purge)
      |> Kernel.++(components_purge)
      |> Kernel.++(storages_purge)
      |> StatePurgeQueue.queue_multiple()

      # Asynchronously populate all related entries
      spawn(fn() ->
        # Server
        store(params)

        # Network
        Enum.each(params.networks, fn(net) ->
          cache(NetworkParams.new(net.network_id, net.ip, params.server_id))
        end)

        # Storage
        Enum.each(params.storages, fn(storage_id) ->
          cache(StorageParams.new(storage_id, params.server_id))
        end)

        # Components
        Enum.each(params.components, fn(component_id) ->
          cache(ComponentParams.new(component_id, params.motherboard_id))
        end)

        cache(ComponentParams.new(params.motherboard_id, params.motherboard_id))
      end)
    else
      StatePurgeQueue.queue(:server, params.server_id)

      spawn(fn() ->
        store(params)
      end)
    end

    {:ok, params}
  end
  defp cache(params = %NetworkParams{}) do
    StatePurgeQueue.queue(:network, [params.network_id, params.ip])
    store(params)
  end
  defp cache(params = %StorageParams{}) do
    StatePurgeQueue.queue(:storage, params.storage_id)
    store(params)
  end
  defp cache(params = %ComponentParams{}) do
    StatePurgeQueue.queue(:component, params.component_id)
    store(params)
  end

  docp """
  Saves the cache on the database. If it already exists, it updates its contents
  along with the new expiration time.
  """
  defp store(params = %ServerParams{}) do
    result = params
    |> ServerCache.create_changeset()
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:server_id])

    case result do
      {:ok, _} ->
        StatePurgeQueue.unqueue(:server, params.server_id)
        result
      _ ->
        result
    end
  end
  defp store(params = %NetworkParams{}) do
    result = params
    |> NetworkCache.create_changeset()
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:network_id, :ip])

    case result do
      {:ok, _} ->
        StatePurgeQueue.unqueue(:network, [params.network_id, params.ip])
        result
      _ ->
        result
    end
  end
  defp store(params = %StorageParams{}) do
    result = params
    |> StorageCache.create_changeset()
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:storage_id])

    case result do
      {:ok, _} ->
        StatePurgeQueue.unqueue(:storage, params.storage_id)
        result
      _ ->
        result
    end
  end
  defp store(params = %ComponentParams{}) do
    result = params
    |> ComponentCache.create_changeset()
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:component_id])

    case result do
      {:ok, _} ->
        StatePurgeQueue.unqueue(:component, params.component_id)
        result
      _ ->
        result
    end
  end
end
