import Helix.Websocket.Request

request Helix.Network.Websocket.Requests.Bounce.Remove do

  import HELL.Macros

  alias Helix.Network.Model.Bounce
  alias Helix.Network.Henforcer.Bounce, as: BounceHenforcer
  alias Helix.Network.Public.Bounce, as: BouncePublic

  def check_params(request, _socket) do
    with {:ok, bounce_id} <- Bounce.ID.cast(request.unsafe["bounce_id"]) do
      update_params(request, %{bounce_id: bounce_id}, reply: true)
    else
      _ ->
        bad_request(request)
    end
  end

  def check_permissions(request, socket) do
    entity_id = socket.assigns.entity_id
    bounce_id = request.params.bounce_id

    case BounceHenforcer.can_remove_bounce?(entity_id, bounce_id) do
      {true, relay} ->
        update_meta(request, %{bounce: relay.bounce}, reply: true)

      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  def handle_request(request, _socket) do
    bounce = request.meta.bounce
    relay = request.relay

    hespawn fn ->
      BouncePublic.remove(bounce, relay)
    end

    reply_ok(request)
  end

  render_empty()
end
