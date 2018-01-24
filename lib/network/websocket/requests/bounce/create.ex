import Helix.Websocket.Request

request Helix.Network.Websocket.Requests.Bounce.Create do

  import HELL.Macros

  alias Helix.Network.Henforcer.Bounce, as: BounceHenforcer
  alias Helix.Network.Public.Bounce, as: BouncePublic
  alias Helix.Network.Websocket.Requests.Bounce.Utils, as: BounceRequestUtils

  def check_params(request, _socket) do
    with \
      {:ok, name} <- validate_input(request.unsafe["name"], :bounce_name),
      {:ok, links} <- BounceRequestUtils.cast_links(request.unsafe["links"])
    do
      params = %{name: name, links: links}

      update_params(request, params, reply: true)
    else
      reason = :bad_link ->
        reply_error(request, reason)

      _ ->
        bad_request(request)
    end
  end

  def check_permissions(request, socket) do
    entity_id = socket.assigns.entity_id
    name = request.params.name
    links = request.params.links

    can_create_bounce =
      BounceHenforcer.can_create_bounce?(entity_id, name, links)

    case can_create_bounce do
      {true, relay} ->
        update_meta(request, %{servers: relay.servers}, reply: true)

      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  def handle_request(request, socket) do
    entity_id = socket.assigns.entity_id
    name = request.params.name
    links = request.params.links
    servers = request.meta.servers
    relay = request.relay

    links = BounceRequestUtils.merge_links(links, servers)

    hespawn fn ->
      BouncePublic.create(entity_id, name, links, relay)
    end

    reply_ok(request)
  end

  render_empty()

  docp """
  Custom error handler for the request. Unmatched terms will get handled by
  general-purpose error translator at `WebsocketUtils.get_error/1`.
  """
  defp get_error(:bad_link),
    do: "bad_link"
end
