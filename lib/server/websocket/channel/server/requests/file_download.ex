defmodule Helix.Server.Websocket.Channel.Server.Requests.FileDownload do

  require Helix.Websocket.Request

  Helix.Websocket.Request.register()

  defimpl Helix.Websocket.Requestable do

    alias Helix.Cache.Query.Cache, as: CacheQuery
    alias Helix.Server.Public.Server, as: ServerPublic
    alias Helix.Software.Model.File
    alias Helix.Software.Model.Storage
    alias Helix.Software.Henforcer.File.Transfer, as: FileTransferHenforcer

    defp get_download_storage(gateway_id) do
      gateway_id
      |> CacheQuery.from_server_get_storages()
      |> elem(1)
      |> List.first()
    end

    def check_params(request, socket) do
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
          # We are actually always returning `file_not_found`, regardless of the
          # internal error, but I'll leave the case here nonetheless
          reason_str =
            case reason do
              {:file, :not_found} ->
                "file_not_found"
              {:file, :not_belongs} ->
                "file_not_found"
              {:storage, :full} ->
                "storage_full"
              {:storage, :not_found} ->
                "bad_storage"
            end

          {:error, %{message: reason_str}}
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

        error = {:error, %{message: _}} ->
          error  # TODO handle me
      end
    end

    def reply(_request, _socket) do
    end
  end
end
