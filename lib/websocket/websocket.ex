defmodule Helix.Websocket do

  use Phoenix.Socket
  use Helix.Logger

  alias Phoenix.Socket
  alias Helix.Event.Notificable
  alias Helix.Account.Model.AccountSession
  alias Helix.Account.Action.Session, as: SessionAction
  alias Helix.Client.Model.Client
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Websocket.Joinable
  alias Helix.Websocket.Request
  alias Helix.Websocket.Requestable
  alias Helix.Websocket.Utils, as: WebsocketUtils

  @type replies ::
    reply_ok
    | reply_error
    | reply_stop
    | no_reply

  @type reply_ok :: {:reply, {:ok, payload}, socket}
  @type reply_error :: {:reply, {:error, payload}, socket}
  @type reply_stop :: {:stop, term, socket}
  @type no_reply :: {:noreply, socket}

  @type meta :: %{request_id: binary | nil}
  @type payload :: %{data: term, meta: meta} | %{data: term}

  @type socket :: Socket.t
  @type t :: socket

  transport :websocket, Phoenix.Transports.WebSocket

  channel "account:*", Helix.Account.Websocket.Channel.Account
  channel "server:*", Helix.Server.Websocket.Channel.Server

  unless Mix.env == :prod do
    channel "logflix", HELL.Logflix
  end

  def connect(%{"token" => token, "client" => client}, socket) do
    client =
      if Client.valid_client?(client) do
        String.to_existing_atom(client)
      else
        :unknown
      end

    do_connect(token, client, socket)
  end

  def connect(%{"token" => token}, socket),
    do: do_connect(token, :unknown, socket)

  def connect(_, _),
    do: :error

  @spec do_connect(AccountSession.token, Client.client, socket) ::
    {:ok, socket}
    | :error
  defp do_connect(token, client, socket) do
    case SessionAction.validate_token(token) do
      {:ok, account, session} ->
        entity_id = EntityQuery.get_entity_id(account.account_id)

        socket =
          socket
          |> assign(:account_id, account.account_id)
          |> assign(:session, session)
          |> assign(:entity_id, entity_id)
          |> assign(:client, client)

        {:ok, socket}
      _ ->
        :error
    end
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
      {:error, %{message: msg}, request} ->
        Joinable.log_error(request, socket, msg)
        {:error, %{data: msg}}

      _ ->
        Joinable.log_error(request, socket, "internal")
        {:error, %{data: "internal"}}
    end
  end

  @doc """
  Generic request handler. It guides the request through the Requestable flow,
  replying the result back to the client.
  """
  def handle_request(request, socket) do
    log :request, nil,
      relay: request.relay,
      type: :debug

    with \
      {:ok, request} <- Requestable.check_params(request, socket),
      {:ok, request} <- Requestable.check_permissions(request, socket),
      {:ok, request} <- Requestable.handle_request(request, socket)
    do
      request
      |> Requestable.reply(socket)
      |> handle_response(request, socket)
    else
      {:error, %{message: msg}, request} ->
        handle_response({:error, %{message: msg}}, request, socket)

      {:error, %{__ready__: error_data}, request} ->
        handle_response({:error, error_data}, request, socket)

      _ ->
        log :internal_error, nil,
          relay: request.relay,
          data: %{status: :error, response: :internal},
          type: :warn

        WebsocketUtils.reply_internal_error(socket)
    end
  end

  @spec generate_payload(term, Request.t) ::
    payload
  defp generate_payload(data, request) do
    %{}
    |> Map.merge(WebsocketUtils.wrap_data(data))
    |> Map.merge(%{meta: generate_meta(request)})
  end

  @spec generate_meta(Request.t) ::
    meta
  defp generate_meta(%{relay: %{request_id: request_id}}),
    do: %{request_id: request_id}

  @spec reply_request({:ok | :error, payload}, socket) ::
    {:reply, {:ok, payload}, socket}
    | {:reply, {:error, payload}, socket}
  defp reply_request({:ok, payload}, socket),
    do: WebsocketUtils.reply_ok(payload, socket)
  defp reply_request({:error, payload}, socket),
    do: WebsocketUtils.reply_error(payload, socket)

  @spec handle_response({:stop, term}, Request.t, socket) :: reply_stop
  @spec handle_response(:noreply, Request.t, socket) :: no_reply
  @spec handle_response({:ok | :error, term}, Request.t, socket) ::
    reply_ok
    | reply_error
  defp handle_response({:stop, reason}, _request, socket),
    do: WebsocketUtils.stop(reason, socket)
  defp handle_response(:noreply, _, socket),
    do: WebsocketUtils.no_reply(socket)
  defp handle_response({status, data}, request, socket) do
    payload = generate_payload(data, request)

    log :response, nil,
      relay: request.relay,
      data: %{status: status, response: data}

    reply_request({status, payload}, socket)
  end

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
