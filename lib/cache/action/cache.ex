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

  import HELL.MacroHelpers

  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Software.Model.Storage
  alias Helix.Cache.Internal.Builder, as: BuilderInternal
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Query.Cache, as: CacheQuery

  def purge_server(server = %Server{}),
    do: purge_server(server.server_id)
  def purge_server(server_id) do
    server = attempt_to_get_data(:server, server_id)

    if not is_nil(server) and not is_nil(server.motherboard_id) do
      Enum.each(server.components, &CacheInternal.purge(:component, &1))
      Enum.each(server.storages, &CacheInternal.purge(:storage, &1))
      CacheInternal.purge(:component, server.motherboard_id)
      Enum.each(
        server.networks,
        &CacheInternal.purge(:network, {&1.network_id, &1.ip})
      )
    end
    CacheInternal.purge(:server, server_id)
  end

  def update_server(server = %Server{}),
    do: update_server(server.server_id)
  def update_server(server_id) do
    params = attempt_to_get_data(:server, server_id, false)
    update_server(server_id, params)
  end
  defp update_server(server_id, params) do
    unless is_nil(params) do
      unless is_nil(params.motherboard_id) do
        Enum.each(params.components, &CacheInternal.update(:component, &1))
        Enum.each(params.storages, &CacheInternal.update(:storage, &1))
        CacheInternal.update(:component, params.motherboard_id)
        Enum.each(
          params.networks,
          &CacheInternal.update(:network, {&1.network_id, &1.ip})
        )
      end
      CacheInternal.update(:server, server_id)
    end
  end

  def update_server_by_motherboard(motherboard = %Motherboard{}),
    do: update_server_by_motherboard(motherboard.motherboard_id)
  def update_server_by_motherboard(motherboard_id) do
    server = attempt_to_get_data(:motherboard, motherboard_id, false)

    # If data is not on the cache, there's no need to update it
    if server do
      update_server(server.server_id, server)
    end
  end

  def update_server_by_storage(storage = %Storage{}),
    do: update_server_by_storage(storage.storage_id)
  def update_server_by_storage(storage_id) do
    server_id = attempt_to_get_data(:storage, storage_id, false)

    if server_id do
      update_server(server_id)
    end
  end

  def update_storage(storage_id) do
    {:ok, server_id} = CacheQuery.from_storage_get_server(storage_id)
    update_server(server_id)
    CacheInternal.update(:storage, storage_id)
  end

  def purge_storage(storage = %Storage{}),
    do: purge_storage(storage.storage_id)
  def purge_storage(storage_id) do
    CacheInternal.purge(:storage, storage_id)
  end

  def update_component(motherboard = %Motherboard{}),
    do: update_component(motherboard.motherboard_id)
  def update_component(component = %Component{}),
    do: update_component(component.component_id)
  def update_component(component_id) do
    # Update server too, if it exists
    server = attempt_to_get_data(:component, component_id, false)

    if server do
      update_server(server.server_id)
    end
    CacheInternal.update(:component, component_id)
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
    update_server(server_id)
    CacheInternal.update(:network, {network_id, ip})
  end

  def purge_nip(network_id, ip) do
    CacheInternal.purge(:network, {network_id, ip})
  end


  docp """
  This is a helper function with the goal of aiding the module to fetch cached
  or original data that is related to whatever is being purged/updated.
  It is ugly, but so am I.

  Notice there's a small but important difference from using this function
  instead of, say, PopulateInternal.fetch_origin, which will fetch the original
  data. Mainly, these are:

  1) It attempts to retrieve cached data first. This is important because, in
  some cases, we only want to purge/update data if it's already cached. Another
  important use is that calling CacheQuery.$function causes side-effects,
  populating the entry if a miss occurs.

  2) Sometimes the underlying data change (most common on purges). This means
  that fetching the origin will fail because that object is no longer valid.
  However, it may still be saved on the cache, and directly querying it will
  give us related data. We know the object isn't valid, but the related data is.

  3) It allows for more custom/flexible logic at the Action layer.
  """
  defp attempt_to_get_data(model, id, origin? \\ true)
  defp attempt_to_get_data(:server, id, origin?) do
    with {:hit, server} <- CacheInternal.direct_query(:server, id) do
      server
    else
      _ ->
        if origin? do
          case BuilderInternal.by_server(id) do
            {:ok, server} ->
              server
            _ ->
              nil
          end
        end
    end
  end
  defp attempt_to_get_data(:motherboard, id, origin?) do
    with {:hit, server} <- CacheInternal.direct_query(:motherboard, id) do
      server
    else
      _ ->
        if origin? do
          case BuilderInternal.by_motherboard(id) do
            {:ok, server} ->
              server
            _ ->
              nil
          end
        end
    end
  end
  defp attempt_to_get_data(:component, id, origin?) do
    with \
      {:hit, mobo} <- CacheInternal.direct_query(:component, id),
      server = %{} <- ServerQuery.fetch_by_motherboard(mobo.motherboard_id)
    do
      server
    else
      _ ->
        if origin? do
          with \
            {:ok, p} <- BuilderInternal.by_component(id),
            server = %{} <- ServerQuery.fetch_by_motherboard(p.motherboard_id)
          do
            server
          else
            _ ->
              nil
          end
        end
    end
  end
  defp attempt_to_get_data(:storage, id, origin?) do
    with {:hit, storage} <- CacheInternal.direct_query(:storage, id) do
      storage.server_id
    else
      _ ->
        if origin? do
          case BuilderInternal.by_storage(id) do
            {:ok, storage} ->
              storage.server_id
            _ ->
              nil
          end
        end
    end
  end
end
