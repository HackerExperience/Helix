import Helix.Websocket.Request

request Helix.Account.Websocket.Channel.Account.Requests.Bootstrap do

  alias Helix.Account.Public.Account, as: AccountPublic

  def check_params(request, _socket),
    do: reply_ok(request)

  def check_permissions(request, _socket),
    do: reply_ok(request)

  def handle_request(request, socket) do
    entity_id = socket.assigns.entity_id

    meta = %{
      bootstrap: AccountPublic.bootstrap(entity_id)
    }

    update_meta(request, meta, reply: true)
  end

  render(request, _socket) do
    data = AccountPublic.render_bootstrap(request.meta.bootstrap)
    {:ok, data}
  end
end
