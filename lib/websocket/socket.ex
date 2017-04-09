defmodule Helix.Websocket.Socket do

  use Phoenix.Socket

  alias Helix.Account.Service.API.Session

  transport :websocket, Phoenix.Transports.WebSocket

  channel "requests", Helix.Websocket.Socket.RequestsChannel
  channel "account:*", Helix.Account.Websocket.Channel.Account

  def connect(%{"token" => token}, socket) do
    case Session.validate_token(token) do
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
end

defmodule Helix.Websocket.Socket.RequestsChannel do

  use Phoenix.Channel

  alias Helix.Account.Websocket.Routes, as: Account

  def join(_topic, _message, socket) do
    # God in the command
    {:ok, socket}
  end

  def handle_in(topic = "account." <> _, params, socket) do
    Account.handle_in(topic, params, socket)
  end

  def handle_in(_, _, socket) do
    {:reply, :error, socket}
  end
end
