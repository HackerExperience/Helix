defmodule Helix.Software.Public.File do

  alias HELL.IPv4
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Software.Action.Flow.File, as: FileFlow
  alias Helix.Software.Action.Flow.FileDownload, as: FileDownloadFlow
  alias Helix.Software.Model.File
  alias Helix.Software.Query.File, as: FileQuery

  # TODO: This will hard fail if the user tries to download a file from their
  #   own gateway for obvious reasons
  # Review: this function returns seems awkward
  @spec download(Server.id, Server.id, Tunnel.t, File.id) ::
    :ok
    | :error
  def download(gateway_id, destination_id, tunnel, file_id) do
    {:ok, gateway_storage_ids} = CacheQuery.from_server_get_storages(gateway_id)
    {:ok, destination_storage_ids} =
      CacheQuery.from_server_get_storages(destination_id)

    gateway_storage = Enum.random(gateway_storage_ids)

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

  @spec bruteforce(Server.id, Network.id, IPv4.t, [Server.id]) ::
    {:ok, Process.t}
    | {:error, %{message: String.t}}
    | FileFlow.error
  @doc """
  Starts a bruteforce attack against `(network_id, target_ip)`, originating from
  `gateway_id` and having `bounces` as intermediaries.
  """
  def bruteforce(gateway_id, network_id, target_ip, bounces) do
    create_params = fn ->
      with \
        {:ok, target_server_id} <-
          CacheQuery.from_nip_get_server(network_id, target_ip)
      do
        %{
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
end
