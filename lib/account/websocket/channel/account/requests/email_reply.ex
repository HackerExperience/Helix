defmodule Helix.Account.Websocket.Channel.Account.Requests.EmailReply do

  require Helix.Websocket.Request

  Helix.Websocket.Request.register()

  defimpl Helix.Websocket.Requestable do

    alias Helix.Websocket.Utils, as: WebsocketUtils
    alias Helix.Account.Public.Account, as: AccountPublic

    def check_params(request, _socket),
      do: {:ok, request}

    def check_permissions(request, _socket),
      do: {:ok, request}

    def handle_request(request, socket) do
      entity_id = socket.assigns.entity_id

      meta = %{bootstrap: AccountPublic.bootstrap(entity_id)}

      {:ok, %{request| meta: meta}}
    end

    def reply(request, socket) do
      data = AccountPublic.render_bootstrap(request.meta.bootstrap)
      WebsocketUtils.reply_ok(data, socket)
    end
  end
end
