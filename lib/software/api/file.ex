defmodule Helix.Software.API.File do

  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Hardware.Query.Component, as: ComponentQuery
  alias Helix.Software.Query.Storage, as: StorageQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Software.Action.Flow.FileDownload, as: FileDownloadFlow
  alias Helix.Software.API.View.File, as: FileView

  def index(destination) do
    destination
    |> ServerQuery.fetch()
    |> storages_on_server()
    # Returns a map %{path => [files]}
    |> Enum.map(&FileQuery.storage_contents/1)
    |> Enum.reduce(%{}, fn el, acc ->
      # Merge the maps, so %{"foo" => [1]} and %{"foo" => [2]} becomes
      # %{"foo" => [1, 2]}
      Map.merge(acc, el, fn _k, v1, v2 -> v1 ++ v2 end)
    end)
    |> Enum.map(fn {path, files} ->
      files = Enum.map(files, &FileView.render/1)

      {path, files}
    end)
    |> :maps.from_list()
  end

  # TODO: This will hard fail if the user tries to download a file from their
  #   own gateway for obvious reasons
  def download(gateway, destination, tunnel, file_id) do
    destination_storage_ids =
      destination
      |> ServerQuery.fetch()
      |> storages_on_server()
      |> Enum.map(&(&1.storage_id))

    gateway_storage =
      gateway
      |> ServerQuery.fetch()
      |> storages_on_server()
      |> Enum.random()

    start_download = fn file_id ->
      FileDownloadFlow.start_download_process(file_id, gateway_storage, tunnel)
    end

    with \
      file = %{} <- FileQuery.fetch(file_id),
      true <- file.storage_id in destination_storage_ids,
      {:ok, _process} <- start_download.(file)
    do
      :ok
    else
      _ ->
        :error
    end
  end

  @spec storages_on_server(struct) ::
  [struct]
  defp storages_on_server(server) do
    server.motherboard_id
    |> ComponentQuery.fetch()
    |> MotherboardQuery.fetch!()
    |> MotherboardQuery.get_slots()
    # TODO: Delegate this to a function on Motherboard API
    # Gets hdds linked to the motherboard
    |> Enum.filter_map(
      &(&1.link_component_type == :hdd && &1.link_component_id),
    &(&1.link_component_id))
    # FIXME: This belongs to an API function that facades this boring shit
    |> Enum.map(&StorageQuery.get_storage_from_hdd/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

end
