import Helix.Websocket.Request

request Helix.Server.Websocket.Requests.Bootstrap do
  @moduledoc """
  ServerBootstrapRequest is used to allow the client to resync its local data
  with the Helix server.

  It returns the ServerBootstrap, which is the exact same struct returned after
  joining a local or remote server Channel.
  """

  alias Helix.Server.Public.Server, as: ServerPublic
  alias Helix.Server.Query.Server, as: ServerQuery

  def check_params(request, _socket),
    do: {:ok, request}

  def check_permissions(request, _socket),
    do: {:ok, request}

  def handle_request(request, socket) do
    entity_id = socket.assigns.entity_id
    server_id = socket.assigns.destination.server_id

    server = ServerQuery.fetch(server_id)

    bootstrap =
      if socket.assigns.meta.access == :local do
        ServerPublic.bootstrap_gateway(server, entity_id)
      else
        ServerPublic.bootstrap_remote(server, entity_id)
      end

    update_meta(request, %{bootstrap: bootstrap}, reply: true)
  end

  render(request, socket) do
    data =
      if socket.assigns.meta.access == :local do
        ServerPublic.render_bootstrap_gateway(request.meta.bootstrap)
      else
        ServerPublic.render_bootstrap_remote(request.meta.bootstrap)
      end

    {:ok, data}
  end
end
