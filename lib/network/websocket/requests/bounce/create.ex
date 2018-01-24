import Helix.Websocket.Request

request Helix.Network.Websocket.Requests.Bounce.Create do

  import HELL.Macros

  alias HELL.IPv4
  alias Helix.Server.Model.Server
  alias Helix.Network.Henforcer.Bounce, as: BounceHenforcer
  alias Helix.Network.Model.Network
  alias Helix.Network.Public.Bounce, as: BouncePublic

  @typep link ::
    %{network_id: Network.id, ip: Network.ip, password: Server.password}

  def check_params(request, _socket) do
    with \
      {:ok, name} <- validate_input(request.unsafe["name"], :bounce_name),
      {:ok, links} <- cast_links(request.unsafe["links"])
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

    # Map `links` to the internal format used by Helix ([Bounce.link])
    links =
      links
      |> Enum.zip(servers)
      |> Enum.map(fn {link, server} ->
        {server.server_id, link.network_id, link.ip}
      end)

    hespawn fn ->
      BouncePublic.create(entity_id, name, links, relay)
    end

    reply_ok(request)
  end

  render_empty()

  @spec get_error(reason :: {term, term} | term) ::
    String.t
  docp """
  Custom error handler for the request. Unmatched terms will get handled by
  general-purpose error translator at `WebsocketUtils.get_error/1`.
  """
  defp get_error(:bad_link),
    do: "bad_link"

  @spec cast_links([{term, term, term}]) ::
    {:ok, [link]}
    | :bad_link
  defp cast_links(links),
    do: Enum.reduce(links, {:ok, []}, &link_reducer/2)

  defp link_reducer(
    %{"network_id" => u_network_id, "ip" => u_ip, "password" => u_pwd},
    {status, acc})
  do
    with \
      {:ok, network_id} <- Network.ID.cast(u_network_id),
      {:ok, ip} <- IPv4.cast(u_ip),
      {:ok, password} <- validate_input(u_pwd, :password)
    do
      {status, acc ++ [%{network_id: network_id, ip: ip, password: password}]}
    else
      _ ->
        :bad_link
    end
  end

  defp link_reducer(_, _),
    do: :bad_link
end
