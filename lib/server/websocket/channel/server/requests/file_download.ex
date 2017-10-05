defmodule Helix.Server.Websocket.Channel.Server.Requests.FileDownload do

  require Helix.Websocket.Request

  Helix.Websocket.Request.register()

  defimpl Helix.Websocket.Requestable do

    import HELL.MacroHelpers

    alias Helix.Websocket.Utils, as: WebsocketUtils
    alias Helix.Cache.Query.Cache, as: CacheQuery
    alias Helix.Software.Model.File
    alias Helix.Software.Model.Storage
    alias Helix.Software.Henforcer.File.Transfer, as: FileTransferHenforcer
    alias Helix.Server.Model.Server
    alias Helix.Server.Public.Server, as: ServerPublic

    # Hack for elixir-lang issue #6577
    @dialyzer({:nowarn_function, get_error: 1})

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

        {:ok, %{request| params: params}}
      else
        :bad_access ->
          {:error, %{message: "download_self"}}
        _ ->
          {:error, %{message: "bad_request"}}
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

          {:ok, %{request| meta: meta}}

        {false, reason, _} ->
          {:error, %{message: get_error(reason)}}
      end
    end

    def handle_request(request, socket) do
      file = request.meta.file
      storage = request.meta.storage
      tunnel = socket.assigns.tunnel

      case ServerPublic.file_download(tunnel, storage, file) do
        {:ok, process} ->
          meta = %{process: process}

          {:ok, %{request| meta: meta}}

        {:error, reason} ->
          {:error, %{message: get_error(reason)}}
      end
    end

    def reply(request, socket) do
      # TODO: Abstract me (#286)
      process = request.meta.process

      file_id = process.file_id && to_string(process.file_id)
      connection_id = process.connection_id && to_string(process.connection_id)

      data = %{
        process_id: to_string(process.process_id),
        type: to_string(process.process_type),
        network_id: to_string(process.network_id),
        file_id: file_id,
        connection_id: connection_id,
        source_ip: socket.assigns.gateway.ip,
        target_ip: request.params.ip
      }

      WebsocketUtils.reply_ok(data, socket)
    end

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
    defp get_error({:file, :not_found}),
      do: "file_not_found"
    defp get_error({:file, :not_belongs}),
      do: "file_not_found"
    defp get_error({:storage, :full}),
      do: "storage_full"
    defp get_error({:storage, :not_found}),
      do: "storage_not_found"
    defp get_error(:internal),
      do: "internal"
  end
end
