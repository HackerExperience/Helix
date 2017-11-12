import Helix.Websocket.Request.Proxy

proxy_request Helix.Client.Websocket.Requests.Setup do
  @moduledoc """
  Top-level proxy (dispatcher) to the clients that implement the Setup page.
  """

  alias Helix.Client.Web1.Websocket.Requests.Setup, as: Web1SetupRequest

  select_backend(request, socket) do
    case socket.assigns.client do
      :web1 ->
        Web1SetupRequest

      _ ->
        false
    end
  end
end
