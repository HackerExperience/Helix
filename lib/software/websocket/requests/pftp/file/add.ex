import Helix.Websocket.Request

request Helix.Software.Websocket.Requests.PFTP.File.Add do
  @moduledoc """
  PFTPFileAddRequest is called when the player wants to add a file to her PFTP.
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
        reply_error("pftp_must_be_local")
      _ ->
        bad_request()
    end
  end

  @doc """
  Most or all permissions are delegated to PFTPHenforcer.
  """
  def check_permissions(request, socket) do
    server_id = socket.assigns.gateway.server_id
    entity_id = socket.assigns.gateway.entity_id
    file_id = request.params.file_id

    case FileHenforcer.PublicFTP.can_add_file?(entity_id, server_id, file_id) do
      {true, relay} ->
        meta = %{
          pftp: relay.pftp,
          file: relay.file
        }

        update_meta(request, meta, reply: true)

      {false, reason, _} ->
        reply_error(reason)
    end
  end

  def handle_request(request, _socket) do
    pftp = request.meta.pftp
    file = request.meta.file

    case PFTPPublic.add_file(pftp, file) do
      {:ok, _pftp_file} ->
        reply_ok(request)

      {:error, reason} ->
        reply_error(reason)
    end
  end

  render_empty()
end
