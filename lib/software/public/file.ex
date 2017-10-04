defmodule Helix.Software.Public.File do

  alias HELL.IPv4
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Software.Action.Flow.File, as: FileFlow
  alias Helix.Software.Action.Flow.File.Transfer, as: FileTransferFlow
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Software.Query.Storage, as: StorageQuery

  @spec download(Tunnel.t, Storage.idt, File.idt) ::
    {:ok, Process.t}
    | {:error, %{message: String.t}}
  def download(tunnel, storage, file_id = %File.ID{}) do
    with file = %{} <- FileQuery.fetch(file_id) do
      download(tunnel, storage, file)
    else
      _ ->
        {:error, %{message: "bad_file"}}
    end
  end

  def download(tunnel, storage_id = %Storage.ID{}, file) do
    storage = StorageQuery.fetch(storage_id)

    if storage do
      download(tunnel, storage, file)
    else
      {:error, %{message: "internal"}}
    end
  end

  def download(tunnel = %Tunnel{}, storage = %Storage{}, file = %File{}) do
    network_info =
      %{
        gateway_id: tunnel.gateway_id,
        destination_id: tunnel.destination_id,
        network_id: tunnel.network_id,
        bounces: []  # TODO
      }

    case FileTransferFlow.transfer(:download, file, storage, network_info) do
      {:ok, process} ->
        {:ok, process}

      {:error, _} ->
        {:error, %{message: "internal"}}
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
      FileQuery.fetch_best(gateway_id, :cracker, :cracker_bruteforce)
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
