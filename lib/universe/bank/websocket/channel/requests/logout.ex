import Helix.Websocket.Request

request Helix.Universe.Bank.Websocket.Requests.Logout do

  alias Helix.Websocket

  def check_params(request, _socket),
    do: reply_ok(request)

  def check_permissions(request, _socket),
    do: reply_ok(request)

  def handle_request(request, socket) do
    socket
    |> Websocket.id()
    |> Helix.Endpoint.broadcast("disconnect", %{})

    reply_ok(request)
  end

  def reply(_request, _socket),
    do: {:stop, :shutdown}
end
