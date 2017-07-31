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
  alias Helix.Cache.Internal.Builder, as: BuilderInternal
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  @doc """
  Populates the corresponding model, based on its primary key.

  These functions are quite expensive in the sense that they may have to query
  several different services in order to compile a denormalized cache.
  """
  def fetch_origin(method, identifier, mark_as_purged?) do
    result = build(method, identifier)
    with \
      {:ok, params} <- result,
      true <- mark_as_purged?
    do
      mark_as_purged(params)
    end

    result
  end

  def populate(method, identifier) do
    result = build(method, identifier)

    with {:ok, params} <- result do
      cache(params)
    end

    result
  end

  defp build(method, identifier) when not is_tuple(identifier),
    do: build(method, {identifier})
  defp build(method, identifier),
    do: apply(BuilderInternal, method, Tuple.to_list(identifier))

  defp mark_as_purged(params = %ServerParams{}) do
    if not is_nil(params.motherboard_id) do
      purge_list = [
        {:server, {params.server_id}},
        {:component, {params.motherboard_id}}
      ]
      networks_purge = Enum.map(params.networks,
        &({:network, {&1.network_id, &1.ip}}))
      components_purge = Enum.map(params.components, &({:component, {&1}}))
      storages_purge = Enum.map(params.storages, &({:storage, {&1}}))

      purge_list
      |> Kernel.++(networks_purge)
      |> Kernel.++(components_purge)
      |> Kernel.++(storages_purge)
      |> StatePurgeQueue.queue_multiple(:update)
    else
      StatePurgeQueue.queue(:server, params.server_id, :update)
    end
  end
  defp mark_as_purged(params = %NetworkParams{}) do
    StatePurgeQueue.queue(:network, {params.network_id, params.ip}, :update)
  end
  defp mark_as_purged(params = %StorageParams{}) do
    StatePurgeQueue.queue(:storage, params.storage_id, :update)
  end
  defp mark_as_purged(params = %ComponentParams{}) do
    StatePurgeQueue.queue(:component, params.component_id, :update)
  end

  docp """
  Coordinates the process of purging and adding cached data to the DB.

  Purging here is required because adding to the DB is asynchronous. This means
  that, if another query comes along while the data is still being populated,
  we won't serve invalid data.
  """
  defp cache(params = %ServerParams{}) do
    # Server
    store(params)

    if not is_nil(params.motherboard_id) do
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

      # Motherboard
      cache(ComponentParams.new(params.motherboard_id, params.motherboard_id))
    end
  end
  defp cache(params = %NetworkParams{}) do
    store(params)
  end
  defp cache(params = %StorageParams{}) do
    store(params)
  end
  defp cache(params = %ComponentParams{}) do
    store(params)
  end

  docp """
  Saves the cache on the database. If it already exists, it updates its contents
  along with the new expiration time.
  """
  defp store(params = %ServerParams{}) do
    params
    |> ServerCache.create_changeset()
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:server_id])
  end
  defp store(params = %NetworkParams{}) do
    params
    |> NetworkCache.create_changeset()
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:network_id, :ip])
  end
  defp store(params = %StorageParams{}) do
    params
    |> StorageCache.create_changeset()
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:storage_id])
  end
  defp store(params = %ComponentParams{}) do
    params
    |> ComponentCache.create_changeset()
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:component_id])
  end
end
