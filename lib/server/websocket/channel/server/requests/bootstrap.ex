defmodule Helix.Server.Websocket.Channel.Server.Requests.Bootstrap do

  require Helix.Websocket.Request

  Helix.Websocket.Request.register()

  defimpl Helix.Websocket.Requestable do

    alias Helix.Websocket.Utils, as: WebsocketUtils
    alias Helix.Server.Public.Server, as: ServerPublic

    def check_params(request, _socket),
      do: {:ok, request}

    def check_permissions(request, socket) do

      if socket.assigns.meta.access_type == :remote do
        {:ok, request}
      else
        {:error, %{message: "own_server_bootstrap"}}
      end
    end

    def handle_request(request, socket) do
      entity_id = socket.assigns.entity_id
      server_id = socket.assigns.destination.server_id

      meta = %{bootstrap: ServerPublic.bootstrap(server_id, entity_id)}

      {:ok, %{request| meta: meta}}
    end

    def reply(request, socket) do
      data = ServerPublic.render_bootstrap(request.meta.bootstrap)
      WebsocketUtils.reply_ok(data, socket)
    end
  end
end
