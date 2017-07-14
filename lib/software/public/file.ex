defmodule Helix.Software.Public.File do

  alias Helix.Hardware.Query.Component, as: ComponentQuery
  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Network.Model.Tunnel
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Software.Action.Flow.FileDownload, as: FileDownloadFlow
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Public.View.File, as: FileView
  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Software.Query.Storage, as: StorageQuery
  alias Helix.Cache.Query.Cache, as: CacheQuery

  @spec index(Server.id) ::
    %{path :: String.t => [map]}
  def index(server_id) do
    server_id
    |> ServerQuery.fetch()
    |> storages_on_server()
    |> Enum.map(&FileQuery.storage_contents/1)
    |> Enum.reduce(%{}, fn el, acc ->
      # Merge the maps, so %{"foo" => [1]} and %{"foo" => [2]} becomes
      # %{"foo" => [1, 2]}
      Map.merge(acc, el, fn _k, v1, v2 -> v1 ++ v2 end)
    end)
    |> Enum.map(fn {path, files} ->
      {path, Enum.map(files, &FileView.render/1)}
    end)
    |> :maps.from_list()
  end

  # TODO: This will hard fail if the user tries to download a file from their
  #   own gateway for obvious reasons
  # Review: this function returns seems awkward
  @spec download(Server.id, Server.id, Tunnel.t, File.id) ::
    :ok
    | :error
  def download(gateway_id, destination_id, tunnel, file_id) do
    destination_storage_ids =
      destination_id
      |> ServerQuery.fetch()
      |> storages_on_server()
      |> Enum.map(&(&1.storage_id))

    gateway_storage =
      gateway_id
      |> ServerQuery.fetch()
      |> storages_on_server()
      |> Enum.random()

    with \
      file = %{} <- FileQuery.fetch(file_id),
      true <- file.storage_id in destination_storage_ids,
      {:ok, _process} <- FileDownloadFlow.start_download_process(
        file,
        gateway_storage,
        tunnel)
    do
      :ok
    else
      _ ->
        :error
    end
  end

  @spec storages_on_server(Server.t) ::
    [Storage.t]
  defp storages_on_server(server) do
    {:ok, storages} = CacheQuery.from_server_get_storages(server.server_id)
    storages
  end
end
