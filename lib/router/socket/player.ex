defmodule Helix.Router.Socket.Player do

  use Phoenix.Socket

  alias Helix.Account.Service.API.Session

  channel "requests", Helix.Router.Channel.PlayerRequests

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

  def id(socket) do
    principal =  Session.principal(socket.assigns.claims)
    "player:" <> principal
  end
end
