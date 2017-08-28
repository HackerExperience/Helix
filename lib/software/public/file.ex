defmodule Helix.Software.Public.File do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Software.Action.Flow.File, as: FileFlow
  alias Helix.Software.Action.Flow.FileDownload, as: FileDownloadFlow
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Public.View.File, as: FileView
  alias Helix.Software.Query.File, as: FileQuery

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

  @spec bruteforce(Server.id, Network.id, Server.id, [Server.id]) ::
    {:ok, Process.t}
    | {:error, %{message: String.t}}
    | FileFlow.error
  @doc """
  Starts a bruteforce attack against `(netwrok_id, target_ip)`, originating from
  `gateway_id` and having `bounces` as intermediaries.
  """
  def bruteforce(gateway_id, network_id, target_ip, bounces) do
    create_params = fn ->
      with \
        gateway_entity = %{} <- EntityQuery.fetch_by_server(gateway_id),
        {:ok, target_server_id} <-
          CacheQuery.from_nip_get_server(network_id, target_ip)
      do
        %{
          source_entity_id: gateway_entity.entity_id,
          target_server_id: target_server_id,
          network_id: network_id,
          target_server_ip: target_ip
        }
      end
    end

    create_meta = fn ->
      %{bounces: bounces}
    end

    get_cracker = fn ->
      FileQuery.fetch_best(gateway_id, :cracker, :bruteforce)
    end

    with \
      params = %{} <- create_params.(),
      meta = create_meta.(),
      cracker = %{} <- get_cracker.() || :no_cracker,
      {:ok, process} <-
        FileFlow.execute_file(cracker, gateway_id, params, meta)
    do
      {:ok, process}
    else
      :no_cracker ->
        {:error, %{message: "cracker_not_found"}}
      error ->
        error
    end
  end

  @spec storages_on_server(Server.t) ::
    [Storage.id]
  defp storages_on_server(server) do
    {:ok, storages} = CacheQuery.from_server_get_storages(server.server_id)
    storages
  end
end
