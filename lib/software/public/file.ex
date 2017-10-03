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
  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Software.Query.Storage, as: StorageQuery

  @spec download(Server.id, Server.id, Tunnel.t, File.id) ::
    {:ok, Process.t}
    | :error
  def download(gateway_id, destination_id, tunnel, file_id) do
    {:ok, gateway_storage_ids} = CacheQuery.from_server_get_storages(gateway_id)

    storage =
      gateway_storage_ids
      |> List.first()
      |> StorageQuery.fetch()

    network_info =
      %{
        gateway_id: gateway_id,
        destination_id: destination_id,
        network_id: tunnel.network_id,
        bounces: []  # TODO
      }

    with \
      true <- not is_nil(storage) || :internal,
      file = %{} <- FileQuery.fetch(file_id) || :bad_file,
      {:ok, process} <-
        FileTransferFlow.transfer(:download, file, storage, network_info)
    do
      {:ok, process}
    else
      :bad_file ->
        {:error, %{message: "bad_file"}}
      :internal ->
        {:error, %{message: "internal"}}
      _ ->
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
