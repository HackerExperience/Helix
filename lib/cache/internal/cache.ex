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
    info = query_info({model, method, :full})
    query(info, params, true)
  end

  @doc """
  Queries the Cache database, populating it if the requested data wasn't found.
  """
  def lookup(condition, params) do
    info = query_info(lookup_table(condition))
    result = process(info, params)
    case result do
      {:ok, data} ->
        {:ok, post_lookup_hook(data)}
      _ ->
        result
    end
  end

  @doc """
  Requests an entry to be purged from cache. It happens asynchronously.
  """
  def purge(model, params) do
    spawn(fn() ->
      apply(PurgeInternal, :purge, [model] ++ params)
    end)
    :ok
  end

  docp """
  Wrapper used to populate cache data in case it isn't stored (miss)
  """
  defp process(info, params) do
    case query(info, params) do
      :miss ->
        apply(PopulateInternal, :populate, [info.module] ++ params)
        |> case do
             {:ok, schema} ->
               {:ok, Map.get(schema, info.field)}
             result ->
               result
            end
      {:hit, data} ->
        {:ok, data}
    end
  end

  docp """
  Generic way to query against all models.

  It usually translates to something like:
  ServerCache.Query.by_server(server_id)
  |> Repo.one
  |> Map.get(:networks)

  The `full?` option tells whether the caller wants the entire row.
  """
  defp query(info, params, full? \\ false) do
    apply(get_module(info.module), info.function, params)
    |> Repo.one
    |> case do
         nil ->
           :miss
         schema ->
           return = if full? do
             schema
           else
             Map.get(schema, info.field)
           end
           {:hit, return}
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
