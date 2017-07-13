defmodule Helix.Cache.Internal.Populate do

  alias Helix.Cache.Repo
  alias Helix.Cache.Model.ServerCache
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Hardware.Query.Component, as: ComponentQuery
  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery

  def populate(:server, server_id) do
    with \
      server = %{} <- ServerQuery.fetch(server_id) || :nxserver,
      true <- not is_nil(server.motherboard_id) || :nxmobo,
      motherboard = %{} <- MotherboardQuery.fetch_by_server(server_id),
      motherboard = MotherboardQuery.preload_components(motherboard),
      resources = %{} <- MotherboardQuery.resources(motherboard),
      components = MotherboardQuery.get_components(motherboard),
      storages = MotherboardQuery.storages_on_motherboard(motherboard),
      networks = MotherboardQuery.get_networks(motherboard),
      entity = %{} <- EntityQuery.fetch_server_owner(server_id)
    do

      data = {server_id, entity, motherboard, networks, storages, resources,
              components}
      params = format(:server, data)
      store!(:server, params)
    else
      :nxserver ->
        {:error, :nxserver}
      :nxmobo ->
        {:error, :nxmobo}
      _ ->
        {:error, :unknown}
    end
  end

  defp format(:server, {server, entity, mobo, networks, storages, resources, components}) do

    network_list = Enum.reduce(networks, [], fn(net, acc) ->
      entry = %{network_id: net.network_id, ip: net.ip}

      acc ++ [entry]
    end)

    storage_list = [storages.storage_id]

    %{
      server_id: server,
      entity_id: entity.entity_id,
      motherboard_id: mobo.motherboard_id,
      components: components,
      resources: resources,
      storages: storage_list,
      networks: network_list
    }
  end

  defp store!(:server, params) do
    params
    |> ServerCache.create_changeset()
    |> Repo.insert!()
  end

end
