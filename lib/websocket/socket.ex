defmodule Helix.Websocket.Socket do

  use Phoenix.Socket

  alias Helix.Account.Action.Session, as: SessionAction
  alias Helix.Websocket.Requestable
  alias Helix.Websocket.Utils, as: WebsocketUtils

  transport :websocket, Phoenix.Transports.WebSocket

  channel "requests", Helix.Websocket.RequestsChannel
  channel "account:*", Helix.Account.Websocket.Channel.Account
  channel "server:*", Helix.Server.Websocket.Channel.Server

  def connect(%{"token" => token}, socket) do
    case SessionAction.validate_token(token) do
      {:ok, account, session} ->
        socket =
          socket
          |> assign(:account, account)
          |> assign(:session, session)

        {:ok, socket}
      _ ->
        :error
    end
  end

  def connect(_, _) do
    :error
  end

  def id(socket),
    do: "session:" <> socket.assigns.session

  def handle_request(request, socket) do
    with \
      {:ok, request} <- Requestable.check_params(request, socket),
      {:ok, request} <- Requestable.check_permissions(request, socket),
      {:ok, request} <- Requestable.handle_request(request, socket)
    do
      Requestable.reply(request, socket)
    else
      {:error, %{message: msg}} ->
        WebsocketUtils.reply_error(msg, socket)
      _ ->
        WebsocketUtils.internal_error(socket)
    end
  end
end
