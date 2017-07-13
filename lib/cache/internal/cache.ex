defmodule Helix.Cache.Internal.Cache do

  alias Helix.Cache.Model.ServerCache
  alias Helix.Cache.Repo
  alias Helix.Cache.Internal.Populate, as: PopulateInternal

  def query_info(module, function, field) do
    %{module: module, function: function, field: field}
  end

  def from_server_get_ip(server_id) do
    info = query_info(:server, :by_server, :networks)
    process(info, [server_id])
  end

  def from_motherboard_get_entity(motherboard_id) do
    info = query_info(:server, :by_motherboard, :entity_id)
    process(info, [motherboard_id])
  end

  def process(info, params) do
    case query(info, params) do
      :miss ->
        apply(PopulateInternal, :populate, [info.module] ++ params)
      {:hit, data} ->
        data
    end
  end

  def query(info, params) do
    apply(get_module(info.module), info.function, params)
    |> Repo.one
    |>  case do
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
    end
  end
end
