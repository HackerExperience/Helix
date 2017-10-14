import Helix.Websocket.Request

request Helix.Software.Websocket.Requests.File.Download do

  import HELL.Macros

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Henforcer.File.Transfer, as: FileTransferHenforcer
  alias Helix.Software.Public.File, as: FilePublic

  # Hack for elixir-lang issue #6577
  @dialyzer {:nowarn_function, get_error: 1}

  def check_params(request, socket) do
    # Fetches the server's main storage if none were specified
    unsafe_storage_id =
      if Map.has_key?(request.unsafe, "storage_id") do
        request.unsafe["storage_id"]
      else
        get_download_storage(socket.assigns.gateway.server_id)
      end

    with \
      true <- socket.assigns.meta.access_type == :remote || :bad_access,
      {:ok, file_id} <- File.ID.cast(request.unsafe["file_id"]),
      {:ok, storage_id} <- Storage.ID.cast(unsafe_storage_id)
    do
      params = %{
        file_id: file_id,
        storage_id: storage_id
      }

      update_params(request, params, reply: true)
    else
      :bad_access ->
        reply_error("download_self")
      _ ->
        bad_request()
    end
  end

  @doc """
  Verifies the permission for the download. Most of the permission logic
  has been delegated to `FileTransferHenforcer.can_transfer?`, check it out.

  This is where we verify the file being download exists, belongs to the
  correct server, the storage belongs to the server, the user has access to
  the storage, etc.
  """
  def check_permissions(request, socket) do
    gateway_id = socket.assigns.gateway.server_id
    destination_id = socket.assigns.destination.server_id
    file_id = request.params.file_id
    storage_id = request.params.storage_id

    can_transfer? =
      FileTransferHenforcer.can_transfer?(
        :download,
        gateway_id,
        destination_id,
        storage_id,
        file_id
      )

    case can_transfer? do
      {true, relay} ->
        meta = %{
          file: relay.file,
          storage: relay.storage
        }

        update_meta(request, meta, reply: true)

      {false, reason, _} ->
        reply_error(reason)
    end
  end

  def handle_request(request, socket) do
    file = request.meta.file
    storage = request.meta.storage
    tunnel = socket.assigns.tunnel

    case FilePublic.download(tunnel, storage, file) do
      {:ok, process} ->
        update_meta(request, %{process: process}, reply: true)

      {:error, reason} ->
        reply_error(reason)
    end
  end

  render_process()

  @spec get_download_storage(Server.id) ::
    Storage.id
  defp get_download_storage(gateway_id) do
    gateway_id
    |> CacheQuery.from_server_get_storages()
    |> elem(1)
    |> List.first()
  end

  @spec get_error(reason :: {term, term} | term) ::
    String.t
  docp """
  Error handler for FileDownloadRequest. Should handle all possible returns.
  """
  defp get_error({:file, :not_belongs}),
    do: "file_not_found"
end
