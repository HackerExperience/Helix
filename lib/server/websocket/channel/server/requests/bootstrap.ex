import Helix.Websocket.Request

request Helix.Server.Websocket.Channel.Server.Requests.Bootstrap do
  @moduledoc """
  ServerBootstrapRequest is used to allow the client to resync its local data
  with the Helix server.

  It returns the ServerBootstrap, which is the exact same struct returned after
  joining a local or remote server Channel.
  """

  alias Helix.Server.Public.Server, as: ServerPublic

  def check_params(request, _socket),
    do: {:ok, request}

  def check_permissions(request, socket) do

    if socket.assigns.meta.access_type == :remote do
      reply_ok(request)
    else
      reply_error("own_server_bootstrap")
    end
  end

  def handle_request(request, socket) do
    entity_id = socket.assigns.entity_id
    server_id = socket.assigns.destination.server_id

    meta = %{
      bootstrap: ServerPublic.bootstrap(server_id, entity_id)
    }

    update_meta(request, meta, reply: true)
  end

  render(request, _socket) do
    data = ServerPublic.render_bootstrap(request.meta.bootstrap)
    {:ok, data}
  end
end
