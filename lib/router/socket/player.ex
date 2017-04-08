defmodule Helix.Router.Socket.Player do

  use Phoenix.Socket

  alias Helix.Account.Service.API.Session

  transport :websocket, Phoenix.Transports.WebSocket

  channel "requests", Helix.Router.Channel.PlayerRequests
  channel "account:*", Helix.Account.WS.Channel.Account

  def connect(%{"token" => token}, socket) do
    case Session.validate_token(token) do
      {:ok, claims} ->
        socket =
          socket
          |> assign(:token, token)
          |> assign(:claims, claims)
        {:ok, socket}
      _ ->
        :error
    end
  end

  def connect(_, _) do
    :error
  end

  # TODO: Use a different value for the ID of the socket, otherwise if the
  #   player logs out of its account on one device, they will be logged out
  #   everywhere
  def id(socket) do
    principal =  Session.principal(socket.assigns.claims)
    "player:" <> principal
  end
end
