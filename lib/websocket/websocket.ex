defmodule Helix.Websocket do

  use Phoenix.Socket

  alias Phoenix.Socket
  alias Helix.Event.Notificable
  alias Helix.Websocket.Joinable
  alias Helix.Websocket.Requestable
  alias Helix.Websocket.Utils, as: WebsocketUtils
  alias Helix.Account.Action.Session, as: SessionAction
  alias Helix.Entity.Query.Entity, as: EntityQuery

  @typep socket :: Socket.t

  transport :websocket, Phoenix.Transports.WebSocket

  channel "requests", Helix.Websocket.RequestsChannel
  channel "account:*", Helix.Account.Websocket.Channel.Account
  channel "server:*", Helix.Server.Websocket.Channel.Server

  def connect(%{"token" => token}, socket) do
    case SessionAction.validate_token(token) do
      {:ok, account, session} ->
        entity_id = EntityQuery.get_entity_id(account.account_id)

        socket =
          socket
          |> assign(:account, account)
          |> assign(:session, session)
          |> assign(:entity_id, entity_id)

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
  Generic join handler. it guides the request through the Joinable flow,
  subscribing the client to the channel in case of success.
  """
  def handle_join(request, socket, assign) do
    with \
      {:ok, request} <- Joinable.check_params(request, socket),
      {:ok, request} <- Joinable.check_permissions(request, socket)
    do
      Joinable.join(request, socket, assign)
    else
      {:error, %{message: msg}} ->
        {:error, %{data: msg}}
      _ ->
        {:error, %{data: "internal"}}
    end
  end

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
      request
      |> Requestable.reply(socket)
      |> reply_request(socket)
    else
      {:error, %{message: msg}} ->
        WebsocketUtils.reply_error(msg, socket)
      _ ->
        WebsocketUtils.internal_error(socket)
    end
  end

  @spec reply_request({:ok | :error} | :noreply, socket) ::
    {:reply, {:ok, %{data: term}}, socket}
    | {:reply, {:error, %{data: term}}, socket}
    | {:noreply, socket}
  defp reply_request({:ok, data}, socket),
    do: WebsocketUtils.reply_ok(data, socket)
  defp reply_request({:error, data}, socket),
    do: WebsocketUtils.reply_error(data, socket)
  defp reply_request(:noreply, socket),
    do: WebsocketUtils.no_reply(socket)

  @doc """
  Generic notification ("event going out") handler. It guides the notification
  through the Notificable flow, making sure the payload sent to the client is
  filtered/censored according to each player's context.

  Once everything is ready, it pushes the payload to the client by using the
  function pointing to the Channel's `push` method, passed as argument.
  """
  def handle_event(event, socket, channel_push) do
    case Notificable.Flow.generate_event(event, socket) do
      {:ok, payload} ->
        channel_push.(socket, "event", payload)

        WebsocketUtils.no_reply(socket)
      _ ->
        WebsocketUtils.no_reply(socket)
    end
  end
end
