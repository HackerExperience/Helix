defmodule Helix.Router.Socket.Player do

  use Phoenix.Socket

  alias Helix.Account.Service.API.Session

  transport :websocket, Phoenix.Transports.WebSocket

  channel "requests", Helix.Router.Channel.PlayerRequests
  channel "account:*", Helix.Account.WS.Channel.Account

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
