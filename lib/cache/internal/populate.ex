defmodule Helix.Cache.Internal.Populate do
  @moduledoc """
  `Populate` is responsible for, well, populating the cache.

  It delegates the responsibility of gathering the "actual" data to the Cache
  Builder module (BuilderInternal)

  `Populate` is only called by StatePurgeQueue during the synchronization step,
  which is coordinated by StateQueueSync.

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
  Attempts to build the original model, based on the given primary key. If it
  succeeds, it *won't* populate the data, but instead it will make sure all
  data related to the object is marked as purged. Only when StatePurgeQueue
  synchronizes will the data be cached.

  The rationale for `fetch_origin/3` is simple: it is used by CacheInternal when
  a miss occurs. We don't want to update the cache right away, hence the sync
  step of StatePurgeQueue. So, `fetch_origin/3` simply returns the relevant data
  and flags it as purged.

  If subsequent queries come through while the data is marked as purged,
  `fetch_origin` will keep getting called, and `BuilderInternal` will keep
  building origin data.

  For a contextualized explanation of the mark_as_purged? param, please see
  (private) docs of `CacheInternal.get_original_data/4`
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

  @doc """
  Populates the corresponding model, based on its primary key.

  Origin data is calculated and returned by BuilderInternal. Actual caching
  happens at the `cache/1` method.
  """
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

  docp """
  This function holds the logic to, given a model and a key, figure out which
  data must be marked as purged. It then notifies StatePurgeQueue, synchronously

  Its logic is usually quite similar to `cache/1`.
  """
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
  Coordinates the process of updating data to the database. It is responsible
  for, given a model and a primary key, figure out which data must be updated
  as well. This function is completely synchronous.

  The coordination logic is similar to the one at `mark_as_purged/1`
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
