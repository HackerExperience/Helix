import Helix.Websocket.Request

request Helix.Software.Websocket.Requests.PFTP.File.Download do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Henforcer.File, as: FileHenforcer
  alias Helix.Software.Public.PFTP, as: PFTPPublic
  alias Helix.Software.Query.Storage, as: StorageQuery

  def check_params(request, socket) do
    unsafe_storage_id =
      if Map.has_key?(request.unsafe, "storage_id") do
        request.unsafe["storage_id"]
      else
        StorageQuery.get_main_storage(socket.assigns.gateway.server_id)
      end

    with \
      true <- socket.assigns.meta.access_type == :local || :not_local,
      {:ok, file_id} <- File.ID.cast(request.unsafe["file_id"]),
      {:ok, network_id, ip} <-
        validate_nip(request.unsafe["network_id"], request.unsafe["ip"]),
      {:ok, target_id} <- CacheQuery.from_nip_get_server(network_id, ip),
      {:ok, storage_id} <- Storage.ID.cast(unsafe_storage_id)
    do
      params = %{
        file_id: file_id,
        storage_id: storage_id,
        target_id: target_id,
        network_id: network_id
      }

      update_params(request, params, reply: true)
    else
      :not_local ->
        reply_error("pftp_must_be_local")

      {:error, {:nip, :notfound}} ->
        reply_error("nip_not_found")

      _ ->
        bad_request()
    end
  end

  def check_permissions(request, socket) do
    server_id = socket.assigns.gateway.server_id
    target_id = request.params.target_id
    storage_id = request.params.storage_id
    file_id = request.params.file_id

    can_transfer? =
      FileHenforcer.Transfer.can_transfer?(
        :download, server_id, target_id, storage_id, file_id
      )

    with \
      {true, r1} <- can_transfer?,
       # /\ Ensures we can download the file
      file = r1.file,
      destination = r1.destination,
      gateway = r1.gateway,

      # Make sure the file exists on a PublicFTP server.
      {true, _} <- FileHenforcer.PublicFTP.file_exists?(destination, file)
    do
      meta = %{
        gateway: gateway,
        destination: destination,
        file: file,
        storage: r1.storage,
      }

      update_meta(request, meta, reply: true)
    else
      {false, reason, _} ->
        reply_error(reason)
    end
  end

  def handle_request(request, _socket) do
    gateway = request.meta.gateway
    destination = request.meta.destination
    file = request.meta.file
    storage = request.meta.storage

    #
    case PFTPPublic.download(gateway, destination, storage, file) do
      {:ok, process} ->
        update_meta(request, %{process: process}, reply: true)

      {:error, reason} ->
        reply_error(reason)
    end
  end

  render_process()
end
