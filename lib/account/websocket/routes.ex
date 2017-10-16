defmodule Helix.Account.Websocket.Routes do

  alias Helix.Websocket
  alias Helix.Account.Websocket.Controller.Account, as: AccountController

  # Note that this is somewhat a hack to allow us to break our request-response
  # channel into several parts (one on each domain). So this code will be
  # executed inside the "requests" channel and thus must follow Phoenix
  # Channel's callback interface:
  # https://hexdocs.pm/phoenix/Phoenix.Channel.html#c:handle_in/3

  def account_logout(socket) do
    AccountController.logout(socket.assigns, %{})

    socket_id = Websocket.id(socket)
    Helix.Endpoint.broadcast(socket_id, "disconnect", %{})

    # Logout will blacklist the token and stop the socket, so, this only makes
    # sense
    {:stop, :shutdown, socket}
  end
end
