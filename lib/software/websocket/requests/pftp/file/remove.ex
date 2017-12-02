import Helix.Websocket.Request

request Helix.Software.Websocket.Requests.PFTP.File.Remove do
  @moduledoc """
  PFTPFileRemoveRequest is called when the player wants to remove a file from
  her PublicFTP server.
  """

  alias Helix.Software.Model.File
  alias Helix.Software.Henforcer.File, as: FileHenforcer
  alias Helix.Software.Public.PFTP, as: PFTPPublic

  @doc """
  All PFTP requests, including `pftp.file.download`, must be performed on the
  local socket.
  """
  def check_params(request, socket) do
    with \
      true <- socket.assigns.meta.access_type == :local || :not_local,
      {:ok, file_id} <- File.ID.cast(request.unsafe["file_id"])
    do
      params = %{
        file_id: file_id
      }

      update_params(request, params, reply: true)
    else
      :not_local ->
        reply_error(request, "pftp_must_be_local")
      _ ->
        bad_request(request)
    end
  end

  @doc """
  Most or all permissions are delegated to PFTPHenforcer.
  """
  def check_permissions(request, socket) do
    server_id = socket.assigns.gateway.server_id
    entity_id = socket.assigns.gateway.entity_id
    file_id = request.params.file_id

    can_remove_file? =
      FileHenforcer.PublicFTP.can_remove_file?(entity_id, server_id, file_id)

    case can_remove_file? do
      {true, relay} ->
        meta = %{
          pftp: relay.pftp,
          pftp_file: relay.pftp_file
        }

        update_meta(request, meta, reply: true)

      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  def handle_request(request, _socket) do
    pftp = request.meta.pftp
    pftp_file = request.meta.pftp_file

    case PFTPPublic.remove_file(pftp, pftp_file) do
      {:ok, _pftp_file} ->
        reply_ok(request)

      {:error, reason} ->
        reply_error(request, reason)
    end
  end

  render_empty()
end
