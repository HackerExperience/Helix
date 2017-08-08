defmodule Helix.Cache.Internal.Cache do
  @moduledoc """
  `InternalCache`, and the whole Cache module, is designed to support plugable
  data models, making it easy to expand and maintain.

  `InternalCache` is the main interface between Cache's Query module, and it's
  responsible for coordinating all other Internal modules.
  """

  import HELL.MacroHelpers

  alias Helix.Cache.Model.Cacheable
  alias Helix.Cache.Model.ComponentCache
  alias Helix.Cache.Model.NetworkCache
  alias Helix.Cache.Model.ServerCache
  alias Helix.Cache.Model.StorageCache
  alias Helix.Cache.Model.WebCache
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue
  alias Helix.Cache.Repo

  @type condition ::
    {atom, atom}
    | atom

  @module_table %{
    :server => ServerCache.Query,
    :component => ComponentCache.Query,
    :network => NetworkCache.Query,
    :storage => StorageCache.Query,
    :web => WebCache.Query
  }

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
    {:network, :server} => {:network, :by_nip, :server_id},

    # Storage
    :storage => {:storage, :by_storage, :all},
    {:storage, :server} => {:storage, :by_storage, :server_id},

    # Component
    :component => {:component, :by_component, :all},
    {:component, :motherboard} => {:component, :by_component, :motherboard_id},

    # Web
    {:web, :content} => {:web, :web_by_nip, :content}
  }

  # @spec lookup(condition, [binary]) ::
  #   {:ok, binary | map}
  #   | {:error, reason :: atom}
  @doc """
  Queries the Cache database, building it from origin if the requested data
  wasn't found.
  """
  def lookup(condition, params) when not is_tuple(params),
    do: lookup(condition, {params})
  def lookup(condition, params) do
    query = query_table(condition)
    full? = query.field == :all
    process(query, params, full?)
  end

  # @spec direct_query(condition, [binary]) ::
  #   {:hit, binary | map}
  #   | :miss
  @doc """
  Directly query the cache without populating it. Reports whether it's a miss
  or hit, along with the cached data (entire row) if it's a hit.
  It is still subject to expired entries, i.e. they will be filtered out. On the
  other hand, it bypasses verification of entries at the PurgeQueue waiting to
  be purged. Use with caution.
  """
  def direct_query(model, params) when not is_tuple(params),
    do: direct_query(model, {params})
  def direct_query(condition, params) do
    query = query_table(condition)
    case sql_query(query, params, true) do
      {:hit, _, original_data} ->
        {:hit, original_data}
      miss ->
        miss
    end
  end

  @doc """
  Requests an entry to be purged from cache.
  Actual deletion of database entries happens asynchronously, but we immediately
  tell the in-memory PurgeQueue DB about this entry. Doing so prevents subsequent
  reads from reading not-yet-purged (stale) data.
  """
  def purge(_, params = %_{id: _}),
    do: raise "bad value #{inspect params}, use only strings"
  def purge(model, params) when not is_tuple(params),
    do: purge(model, {params})
  def purge(model, params),
    do: StatePurgeQueue.queue(model, params, :purge)

  @doc """
  Requests an entry to be repopulated (updated) on the cache.
  Actual update of database entries happens asynchronously, but we immediately
  tell the in-memory PurgeQueue DB about this entry. Doing so prevents subsequent
  reads from reading not-yet-purged (stale) data.
  """
  def update(_, params = %_{id: _}),
    do: raise "bad value #{inspect params}, use only strings"
  def update(model, params) when not is_tuple(params),
    do: update(model, {params})
  def update(model, params),
    do: StatePurgeQueue.queue(model, params, :update)

  docp """
  Wrapper used to query origin data in case it isn't cached (miss)
  """
  defp process(query, params, full?) do
    with {:hit, data, _} <- query(query, params, full?) do
      {:ok, data}
    else
      {:miss, reason} ->
        get_original_data(reason, query, params, full?)
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
  |> Repo.one()
  |> Map.get(:networks)

  The `full?` option tells whether the caller wants the entire row or
  a single field.

  In case of hit, it returns both the original row and the formatted output.
  It's up to the caller to decide which one to use.
  """
  defp sql_query(query, params, full?) do
    fetch = apply(query.module, query.function, Tuple.to_list(params))
    apply(query.module, :filter_expired, [fetch])
    |> Repo.one()
    |> case do
         nil ->
           {:miss, :notfound}
         schema ->
           # Reformat the result to Helix internal representation
           clean_schema = Cacheable.format_output(schema)
           if full? do
             {:hit, clean_schema, schema}
           else
             field = Map.get(clean_schema, query.field)
             {:hit, field, field}
           end
       end
  end

  docp """
  We've tried to fetch the data but it isn't cached. This may be for three
  reasons:

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
    # On the other hand, if the reason is that the entry does not exist on the
    # DB, we will populate it soon, and as such we want to mark as purged.
    mark_as_purged? = reason == :notfound
    args = [query.function, params, mark_as_purged?]

    case apply(PopulateInternal, :fetch_origin, args) do
      {:ok, schema} ->
        if full? do
          {:ok, schema}
        else
          {:ok, Map.get(schema, query.field)}
        end
      error ->
        error
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

  defp get_module(model),
    do: @module_table[model] || raise "Invalid model #{inspect model}"
end
