import Helix.Websocket.Request

request Helix.Server.Websocket.Requests.SetHostname do

  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Public.Server, as: ServerPublic

  def check_params(request, _socket) do
    with \
      true <- not is_nil(request.unsafe["hostname"]),
      hostname = request.unsafe["hostname"]
    do
      update_params(request, %{hostname: hostname}, reply: true)
    else
      _ ->
        bad_request()
    end
  end

  def check_permissions(request, socket) do
    entity_id = socket.assigns.gateway.entity_id
    server_id = socket.assigns.gateway.server_id
    hostname = request.params.hostname

    case ServerHenforcer.can_set_hostname?(entity_id, server_id, hostname) do
      {true, relay} ->
        request
        |> update_params(%{hostname: relay.hostname})
        |> update_meta(%{server: relay.server}, reply: true)

      {false, reason, _} ->
        reply_error(reason)
    end
  end

  def handle_request(request, _socket) do
    server = request.meta.server
    hostname = request.params.hostname
    relay = request.relay

    case ServerPublic.set_hostname(server, hostname, relay) do
      {:ok, _server} ->
        reply_ok(request)

      {:error, reason} ->
        reply_error(reason)
    end
  end

  render_empty()
end
