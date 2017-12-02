import Helix.Websocket.Request

request Helix.Software.Websocket.Requests.PFTP.Server.Disable do
  @moduledoc """
  PFTPServerDisableRequest is called when the player wants to disable his
  PublicFTP server.
  """

  alias Helix.Software.Henforcer.File, as: FileHenforcer
  alias Helix.Software.Public.PFTP, as: PFTPPublic

  @doc """
  All PFTP requests, including `pftp.file.download`, must be performed on the
  local socket.
  """
  def check_params(request, socket) do
    if socket.assigns.meta.access_type == :local do
      reply_ok(request)
    else
      reply_error(request, "pftp_must_be_local")
    end
  end

  @doc """
  Most or all permissions are delegated to PFTPHenforcer.
  """
  def check_permissions(request, socket) do
    server_id = socket.assigns.gateway.server_id
    entity_id = socket.assigns.gateway.entity_id

    case FileHenforcer.PublicFTP.can_disable_server?(entity_id, server_id) do
      {true, relay} ->
        meta = %{pftp: relay.pftp}
        update_meta(request, meta, reply: true)

      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  def handle_request(request, _socket) do
    pftp = request.meta.pftp

    case PFTPPublic.disable_server(pftp) do
      {:ok, _pftp} ->
        reply_ok(request)

      {:error, reason} ->
        reply_error(request, reason)
    end
  end

  @doc """
  Renders an empty response. Client will receive only a successful return code.

  Client shall soon receive a PFTPServerDisabledEvent.
  """
  render_empty()

  defp get_error({:pftp, :disabled}),
    do: "pftp_already_disabled"
end
