import Helix.Websocket.Request

request Helix.Account.Websocket.Requests.Logout do
  @moduledoc """
  Invalidates the session token and shuts down the socket.
  """

  alias Helix.Websocket
  alias Helix.Account.Websocket.Controller.Account, as: AccountController

  def check_params(request, _socket),
    do: reply_ok(request)

  def check_permissions(request, _socket),
    do: reply_ok(request)

  def handle_request(request, socket) do

    AccountController.logout(socket.assigns, %{})

    socket
    |> Websocket.id()
    |> Helix.Endpoint.broadcast("disconnect", %{})

    reply_ok(request)
  end

  def reply(_request, _socket),
    do: {:stop, :shutdown}
end
