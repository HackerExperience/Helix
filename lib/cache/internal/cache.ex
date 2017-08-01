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

  # @spec direct_query(condition, [binary]) ::
  #   {:hit, binary | map}
  #   | :miss
  @doc """
  Directly query the cache without populating it. Reports whether it's a miss
  or hit, along with the cached data (entire row) if it's a hit.
  """
  def direct_query(model, params) when not is_tuple(params) do
    direct_query(model, {params})
  end
  def direct_query(condition, params) do
    query = query_table(condition)
    result = sql_query(query, params, true)
    case result do
      {:hit, data} ->
        {:hit, post_lookup_hook(data)}
      {:miss, :notfound} ->
        :miss
    end
  end

  # @spec lookup(condition, [binary]) ::
  #   {:ok, binary | map}
  #   | {:error, reason :: atom}
  @doc """
  Queries the Cache database, populating it if the requested data wasn't found.
  """
  def lookup(condition, params) when not is_tuple(params),
    do: lookup(condition, {params})
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
  def purge(model, params) when not is_tuple(params),
    do: purge(model, {params})
  def purge(model, params) do
    StatePurgeQueue.queue(model, params, :purge)

    :ok
  end

  @doc """
  Requests an entry to be repopulated (updated) on the cache.
  Actual update of database entries happens asynchronously, but we immediately
  tell the in-memory PurgeQueue DB about this entry. Doing so prevents subsequent
  reads from reading not-yet-purged (stale) data.
  """
  def update(model, params) when not is_tuple(params),
    do: update(model, {params})
  def update(model, params) do
    PurgeInternal.invalidate_entries(model, params)

    :ok
  end


  docp """
  Wrapper used to query origin data in case it isn't cached (miss)
  """
  defp process(query, params, full?) do
    with {:hit, data} <- query(query, params, full?) do
      {:ok, data}
    else
      {:miss, reason} ->
        get_original_data(reason, query, params, full?)
    end
  end

  docp """
  We've tried to fetch the data but it isn't cached. This may be for two reasons:
  1) Entry is not on the DB
  2) Entry is on the DB but it's expired
  3) Entry is on the DB and valid, but marked as purged on the PurgeQueue

  For the first two cases, we want to notify the PurgeQueue about this entry.
  For the latter case, however, there's no point on notifying PurgeQueue because
  it already knows the entry is invalid.

  This function fetches the actual data (from the origin), passing the reason
  of the miss downstream, which will know whether it should notify PurgeQueue.
  """
  defp get_original_data(reason, query, params, full?) do
    # If we can't find the data because it's purged, there's no need to mark it
    # as purged (because it already is marked as purged).
    # On the other hand, if the reason is that the entry does not exist on the DB,
    # we will populate it soon, and as such we want to mark as purged.
    mark_as_purged? = reason == :notfound

    result = apply(
      PopulateInternal,
      :fetch_origin,
      [query.function, params, mark_as_purged?]
    )

    case result do
      {:ok, schema} ->
        if full? do
          {:ok, Map.from_struct(schema)}
        else
          {:ok, Map.get(schema, query.field)}
        end
      error ->
        error
    end
  end

  docp """
  This intermediary step first checks whether the entry is queued up for
  deletion on the PurgeQueue in-memory table. If this is the case, return a
  miss right away (which will later be repopulated).
  If it's not queued for deletion, actually query the database.
  """
  defp query(query, params, full?) do
    if not StatePurgeQueue.lookup(query.model, params) do
      sql_query(query, params, full?)
    else
      {:miss, :purged}
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
    fetch = apply(query.module, query.function, Tuple.to_list(params))
    apply(query.module, :filter_expired, [fetch])
    |> Repo.one
    |> case do
         nil ->
           {:miss, :notfound}
         schema ->
           if full? do
             {:hit, schema}
           else
             {:hit, Map.get(schema, query.field)}
           end
       end
  end

  defp get_module(model) do
    case model do
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
      {model, function, field} ->
        %{module: get_module(model),
          function: function,
          field: field,
          model: model}
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
