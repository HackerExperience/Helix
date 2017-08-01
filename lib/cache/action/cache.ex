defmodule Helix.Cache.Action.Cache do
  @moduledoc """
  Welcome to the Cache invalidation API. Here's a few things you should know:

  - I, the Cache, am responsible for transparent synchronization and invalidation
  of cached data.
  - YOU, the programmer, is responsible for telling me about changes on the data.
  - Caching is hard. Don't blame me.
  - Never use Internal modules directly.

  You can request me to either **update** or **purge** (delete) data, but I'll get
  quite mad if you ask me to do an action I'm not supposed to. Basically:

  - Purge data when its underlying object has been effectively deleted.
  - For all other cases, you probably want to update the data.

  Here's why:

  When you tell me an object has been updated, I'll grab everything we know about
  it and create related entries. For instance, if you tell me an IP address has
  changed, I'll take care of ensuring that any related entries have been updated.

  But suppose you just deleted a component (maybe the player sold it). If you tell
  me that that component has been updated, I won't be able to fetch any information
  from it (because it no longer exists). Furthermore, updates will always lead to
  new data being added to cache, and I definitely shouldn't add something that just
  got deleted.

  In this case, you should notify me that:
  - the component has been deleted, so I can purge it from my database.
  - relevant entries, for instance the server, were updated. (don't worry,
  usually one purge affects only one object).

  Follow these rules and no one will get hurt.
  """

  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  def purge_server(server = %Server{}),
    do: purge_server(server.server_id)
  def purge_server(server_id) do
    server =
      with {:ok, server} <- CacheQuery.from_server_get_all(server_id) do
        server
      else
        _ ->
          case CacheInternal.direct_query(:server, server_id) do
            {:hit, server} ->
              server
            _ ->
              nil
          end
      end

    if server do
      Enum.each(server.networks, &purge_nip(&1.network_id, &1.ip))
      Enum.each(server.components, &purge_component(&1))
      Enum.each(server.storages, &purge_storage(&1))
      purge_component(server.motherboard_id)
    end
    CacheInternal.purge(:server, server_id)
  end

  def update_server(server = %Server{}),
    do: update_server(server.server_id)
  def update_server(server_id) do
    CacheInternal.update(:server, server_id)
  end

  def update_storage(storage_id) do
    {:ok, server_id} = CacheQuery.from_storage_get_server(storage_id)
    update_storage(storage_id, server_id)
  end
  defp update_storage(storage_id, server_id) do
    StatePurgeQueue.queue(:storage, storage_id, :update)
    CacheInternal.update(:server, server_id)
  end

  def purge_storage(storage_id) do
    CacheInternal.purge(:storage, storage_id)
  end

  def update_component(motherboard = %Motherboard{}),
    do: update_component(motherboard.motherboard_id)
  def update_component(component = %Component{}),
    do: update_component(component.component_id)
  def update_component(component_id) do
    # Update server too, if it exists
    with \
      {:ok, mobo_id} <- CacheQuery.from_component_get_motherboard(component_id),
      server = %{} <- ServerQuery.fetch_by_motherboard(mobo_id)
    do
      update_server(server.server_id)
    else
      _ ->
        CacheInternal.update(:component, component_id)
    end
  end

  def purge_component(motherboard = %Motherboard{}),
    do: purge_component(motherboard.motherboard_id)
  def purge_component(component = %Component{}),
    do: purge_component(component.component_id)
  def purge_component(component_id) do
    CacheInternal.purge(:component, component_id)
  end

  def update_nip(network_id, ip) do
    {:ok, server_id} = CacheQuery.from_nip_get_server(network_id, ip)
    update_nip(network_id, ip, server_id)
  end
  defp update_nip(network_id, ip, server_id) do
    StatePurgeQueue.queue(:network, {network_id, ip}, :update)
    CacheInternal.update(:server, server_id)
  end

  def purge_nip(network_id, ip) do
    CacheInternal.purge(:network, {network_id, ip})
  end
end
