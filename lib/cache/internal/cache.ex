defmodule Helix.Cache.Internal.Cache do
  @moduledoc """
  `InternalCache`, and the whole Cache module, is designed to support plugable
  data models, making it easy to expand and maintain.

  `InternalCache` is the main interface between Cache's Query module, and it's
  responsible for coordinating all other Internal modules.
  """

  alias Helix.Cache.Model.ServerCache
  alias Helix.Cache.Model.NetworkCache
  alias Helix.Cache.Model.StorageCache
  alias Helix.Cache.Model.ComponentCache
  alias Helix.Cache.Repo
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Internal.Purge, as: PurgeInternal
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  import HELL.MacroHelpers

  @doc """
  Directly query the cache without populating it. Reports whether it's a miss
  or hit, along with the cached data (entire row) if it's a hit.
  """
  def direct_query(model, params) when not is_list(params) do
    direct_query(model, [params])
  end
  def direct_query(model, params) when is_atom(model) do
    model = case model do
      :server ->
        {:server, :by_server}
      :motherboard ->
        {:server, :by_motherboard}
      :storage ->
        {:storage, :by_storage}
      :component ->
        {:component, :by_component}
      :network ->
        {:network, :by_nip}
    end
    direct_query(model, params)
  end
  def direct_query({model, method}, params) do
    info = query_info({model, method, :all})
    result = sql_query(info, params, true)
    case result do
      {:hit, data} ->
        {:hit, post_lookup_hook(data)}
      _ ->
        result
    end
  end

  @doc """
  Queries the Cache database, populating it if the requested data wasn't found.
  """
  def lookup(condition, params) do
    info = query_info(lookup_table(condition))
    full? = if info.field == :all do
      true
    else
      false
    end
    result = process(info, params, full?)
    case result do
      {:ok, data} ->
        {:ok, post_lookup_hook(data)}
      _ ->
        result
    end
  end

  def is_marked_as_purged(model, params) when not is_list(params),
    do: is_marked_as_purged(model, [params])
  def is_marked_as_purged(model, params) do
    StatePurgeQueue.lookup(model, params)
  end

  def mark_multiple_as_purged(entry_list) do
    StatePurgeQueue.queue_multiple(entry_list)
  end

  def mark_as_purged(model, params) when not is_list(params),
    do: mark_as_purged(model, [params])
  def mark_as_purged(model, params) do
    StatePurgeQueue.queue(model, params)
  end

  def remove_from_purge_queue(model, params) when not is_list(params),
    do: remove_from_purge_queue(model, [params])
  def remove_from_purge_queue(model, params) do
    StatePurgeQueue.unqueue(model, params)
  end

  @doc """
  Requests an entry to be purged from cache.
  Actual deletion of database entries happens asynchronously, but we immediately
  tell the in-memory PurgeQueue DB about this entry. Doing so prevents subsequent
  reads from reading not-yet-purged (stale) data.
  """
  def purge(model, params) when not is_list(params),
    do: purge(model, [params])
  def purge(model, params) do
    # Synchronously mark entry as invalid by adding it to the PurgeQueue
    mark_as_purged(model, params)

    # Asynchronously delete stuff from the DB
    spawn(fn() ->
      apply(PurgeInternal, :purge, [model] ++ params)
    end)

    :ok
  end

  docp """
  Wrapper used to populate cache data in case it isn't stored (miss)
  """
  defp process(info, params, full?) do
    case query(info, params, full?) do
      :miss ->
        apply(PopulateInternal, :populate, [info.module] ++ params)
        |> case do
             {:ok, schema} ->
               if full? do
                 {:ok, schema}
               else
                 {:ok, Map.get(schema, info.field)}
               end
             result ->
               result
            end
      {:hit, data} ->
        {:ok, data}
    end
  end

  docp """
  This intermediary step first checks whether the entry is queued up for deletion
  on the PurgeQueue in-memory table. If this is the case, return a miss right away
  (which will later be repopulated).
  If it's not queued for deletion, actually query the database.
  """
  defp query(info, params, full? \\ false) do
    unless StatePurgeQueue.lookup(info.module, params) do
      sql_query(info, params, full?)
    else
      :miss
    end
  end

  docp """
  Generic way to query against all models.

  It usually translates to something like:
  ServerCache.Query.by_server(server_id)
  |> ServerCache.Query.filter_expired()
  |> Repo.one
  |> Map.get(:networks)

  The `full?` option tells whether the caller wants the entire row.
  """
  defp sql_query(info, params, full?) do
    fetch = apply(get_module(info.module), info.function, params)
    apply(get_module(info.module), :filter_expired, [fetch])
    |> Repo.one
    |> case do
         nil ->
           :miss
         schema ->
           if full? do
             {:hit, schema}
           else
             {:hit, Map.get(schema, info.field)}
           end
       end
  end

  defp get_module(module) do
    case module do
      :server ->
        ServerCache.Query
      :network ->
        NetworkCache.Query
      :storage ->
        StorageCache.Query
      :component ->
        ComponentCache.Query
    end
  end

  defp query_info({module, function, field}) do
    %{module: module, function: function, field: field}
  end

  docp """
  Static representation of all possible queries

  The 3-tuple means something like:
  (model_being_used, how_to_query, what_to_return)
  """
  defp lookup_table(condition) do
    case condition do
      :server ->
        {:server, :by_server, :all}
      {:server, :nips} ->
        {:server, :by_server, :networks}
      {:server, :storages} ->
        {:server, :by_server, :storages}
      {:server, :resources} ->
        {:server, :by_server, :resources}
      {:server, :components} ->
        {:server, :by_server, :components}
      {:motherboard, :entity} ->
        {:server, :by_motherboard, :entity_id}
      {:motherboard, :resources} ->
        {:server, :by_motherboard, :resources}
      {:motherboard, :components} ->
        {:server, :by_motherboard, :components}
      {:entity, :motherboard} ->
        {:server, :by_entity, :motherboard_id}
      {:storage, :server} ->
        {:storage, :by_storage, :server_id}
      {:nip, :server} ->
        {:network, :by_nip, :server_id}
      {:component, :motherboard} ->
        {:component, :by_component, :motherboard_id}
      _ ->
        raise RuntimeError
    end
  end

  docp """
  Simple hook for post-processing of cache returns.

  Mostly useful for transforming map keys from strings to atoms.
  """
  defp post_lookup_hook(data) do
    if is_list(data) or is_map(data) do
      map_to_atoms(data)
    else
      data
    end
  end

  defp ecto_enum(schema, fields) do
    Enum.reduce(fields, %{}, fn(field, acc) ->
      case field do
        :expiration_date ->
          Map.put(acc, field, schema.expiration_date)
        _ ->
          Map.put(acc, field, map_to_atoms(Map.get(schema, field)))
      end
    end)
  end

  defp map_to_atoms(data = %StorageCache{}) do
    ecto_enum(data, StorageCache.__schema__(:fields))
  end
  defp map_to_atoms(data = %ComponentCache{}) do
    ecto_enum(data, ComponentCache.__schema__(:fields))
  end
  defp map_to_atoms(data = %NetworkCache{}) do
    ecto_enum(data, NetworkCache.__schema__(:fields))
  end
  defp map_to_atoms(data = %ServerCache{}) do
    ecto_enum(data, ServerCache.__schema__(:fields))
  end
  defp map_to_atoms(data) when is_list(data) do
    Enum.map(data, fn(elem) ->
      map_to_atoms(elem)
    end)
  end
  defp map_to_atoms(data) when is_map(data) do
    data
    |> Enum.reduce(%{}, fn ({key, val}, acc) ->
      key = if is_atom(key) do
        key
      else
        String.to_existing_atom(key)
      end
      Map.put(acc, key, val)
    end)
  end
  defp map_to_atoms(data),
    do: data
end
