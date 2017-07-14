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

  import HELL.MacroHelpers

  @doc """
  Queries the Cache database, populating it if the requested data wasn't found.
  """
  def lookup(condition, params) do
    info = query_info(lookup_table(condition))
    result = process(info, params)
    post_lookup_hook(result)
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
  """
  defp query(info, params) do
    apply(get_module(info.module), info.function, params)
    |> Repo.one
    |> case do
         nil ->
           :miss
         schema ->
           {:hit, Map.get(schema, info.field)}
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
  defp post_lookup_hook(result) do
    case result do
      {:ok, data} ->
        if is_list(data) or is_map(data) do
          {:ok, map_to_atoms(data)}
        else
          result
        end
      _ ->
        result
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
