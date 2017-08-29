defmodule Helix.Websocket.Socket do

  use Phoenix.Socket

  alias Helix.Event.Notificable
  alias Helix.Websocket.Requestable
  alias Helix.Websocket.Utils, as: WebsocketUtils
  alias Helix.Account.Action.Session, as: SessionAction

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

  @doc """
  Generic request handler. It guides the request through the Requestable flow,
  replying the result back to the client.
  """
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

  @doc """
  Generic notification ("event going out") handler. It guides the notification
  through the Notificable flow, making sure the payload sent to the client is
  filtered/censored according to each player's context.

  Once everything is ready, it pushes the payload to the client by using the
  function pointing to the Channel's `push` method, passed as argument.
  """
  def handle_event(event, socket, channel_push) do
    case Notificable.generate_payload(event, socket) do
      {:ok, data} ->
        channel_push.(socket, "event", data)

        WebsocketUtils.no_reply(socket)
      _ ->
        WebsocketUtils.no_reply(socket)
    end
  end
end
