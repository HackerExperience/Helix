import Helix.Websocket.Request

request Helix.Client.Web1.Websocket.Requests.Setup do

  def check_params(request, socket) do
    {:ok, request}
  end

  def check_permissions(request, socket) do
    {:ok, request}
  end

  def handle_request(request, socket) do
    {:ok, request}
  end

  render_empty()
end
