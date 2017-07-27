defmodule Helix.Cache.Internal.Cache do
  @moduledoc """
  `InternalCache`, and the whole Cache module, is designed to support plugable
  data models, making it easy to expand and maintain.

  `InternalCache` is the main interface between Cache's Query module, and it's
  responsible for coordinating all other Internal modules.
  """

  import HELL.MacroHelpers

  alias Helix.Cache.Model.ComponentCache
  alias Helix.Cache.Model.NetworkCache
  alias Helix.Cache.Model.ServerCache
  alias Helix.Cache.Model.StorageCache
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Internal.Purge, as: PurgeInternal
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue
  alias Helix.Cache.Repo

  @type condition ::
    {atom, atom}
    | atom

  docp """
  Static representation of all possible queries

  The 3-tuple means something like:
  (model_being_used, how_to_query, what_to_return)
  """
  @query_table %{
    # Server
    :server => {:server, :by_server, :all},
    :motherboard => {:server, :by_motherboard, :all},
    {:server, :nips} => {:server, :by_server, :networks},
    {:server, :storages} => {:server, :by_server, :storages},
    {:server, :resources} => {:server, :by_server, :resources},
    {:server, :components} => {:server, :by_server, :components},
    {:motherboard, :entity} => {:server, :by_motherboard, :entity_id},
    {:motherboard, :resources} => {:server, :by_motherboard, :resources},
    {:motherboard, :components} => {:server, :by_motherboard, :components},
    {:entity, :motherboard} => {:server, :by_entity, :motherboard_id},

    # Network
    :network => {:network, :by_nip, :all},
    {:nip, :server} => {:network, :by_nip, :server_id},

    # Storage
    :storage => {:storage, :by_storage, :all},
    {:storage, :server} => {:storage, :by_storage, :server_id},

    # Component
    :component => {:component, :by_component, :all},
    {:component, :motherboard} => {:component, :by_component, :motherboard_id}
  }

  @spec direct_query(condition, [binary]) ::
    {:hit, binary | map}
    | :miss
  @doc """
  Directly query the cache without populating it. Reports whether it's a miss
  or hit, along with the cached data (entire row) if it's a hit.
  """
  def direct_query(model, params) when not is_list(params) do
    direct_query(model, [params])
  end
  def direct_query(condition, params) do
    query = query_table(condition)
    result = sql_query(query, params, true)
    case result do
      {:hit, data} ->
        {:hit, post_lookup_hook(data)}
      _ ->
        result
    end
  end

  @spec lookup(condition, [binary]) ::
    {:ok, binary | map}
    | {:error, reason :: atom}
  @doc """
  Queries the Cache database, populating it if the requested data wasn't found.
  """
  def lookup(condition, params) do
    query = query_table(condition)
    full? = query.field == :all
    result = process(query, params, full?)
    case result do
      {:ok, data} ->
        {:ok, post_lookup_hook(data)}
      _ ->
        result
    end
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
    StatePurgeQueue.queue(model, params)

    # Asynchronously delete stuff from the DB
    spawn(fn() ->
      apply(PurgeInternal, :purge, [model] ++ [params])
    end)

    :ok
  end

  @doc """
  Requests an entry to be repopulated (updated) on the cache.
  Actual update of database entries happens asynchronously, but we immediately
  tell the in-memory PurgeQueue DB about this entry. Doing so prevents subsequent
  reads from reading not-yet-purged (stale) data.
  """
  def update(model, params) when not is_list(params),
    do: update(model, [params])
  def update(model, params) do
    # Synchronously mark entry as invalid by adding it to the PurgeQueue
    StatePurgeQueue.queue(model, params)

    # Asynchronously update stuff on the DB
    spawn(fn() ->
      apply(PurgeInternal, :update, [model] ++ params)
    end)

    :ok
  end


  docp """
  Wrapper used to populate cache data in case it isn't stored (miss)
  """
  defp process(query, params, full?) do
    case query(query, params, full?) do
      :miss ->
        apply(PopulateInternal, :populate, [query.module] ++ params)
        |> case do
             {:ok, schema} ->
               if full? do
                 {:ok, Map.from_struct(schema)}
               else
                 {:ok, Map.get(schema, query.field)}
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
  defp query(query, params, full?) do
    if not StatePurgeQueue.lookup(query.module, params) do
      sql_query(query, params, full?)
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

  The `full?` option tells whether the caller wants the entire row or
  a single field.
  """
  defp sql_query(query, params, full?) do
    fetch = apply(get_module(query.module), query.function, params)
    apply(get_module(query.module), :filter_expired, [fetch])
    |> Repo.one
    |> case do
         nil ->
           :miss
         schema ->
           if full? do
             {:hit, schema}
           else
             {:hit, Map.get(schema, query.field)}
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

  docp """
  Iterates over the query table, ensuring the requested query is valid.
  """
  def query_table(condition) do
    case @query_table[condition] do
      {module, function, field} ->
        %{module: module, function: function, field: field}
      _ ->
        raise RuntimeError, "Query #{inspect condition} is invalid"
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
