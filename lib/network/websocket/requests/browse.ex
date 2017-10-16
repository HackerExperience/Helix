import Helix.Websocket.Request

request Helix.Network.Websocket.Requests.Browse do

  alias Helix.Server.Model.Server
  alias Helix.Software.Public.PFTP, as: PFTPPublic
  alias Helix.Network.Model.Network
  alias Helix.Network.Henforcer.Network, as: NetworkHenforcer
  alias Helix.Network.Public.Network, as: NetworkPublic

  def check_params(request, socket) do
    gateway_id = socket.assigns.gateway.server_id
    destination_id = socket.assigns.destination.server_id

    origin_id =
      if Map.has_key?(request.unsafe, "origin") do
        request.unsafe["origin"]
      else
        socket.assigns.destination.server_id
      end

    with \
      {:ok, network_id} <-
        Network.ID.cast(request.unsafe["network_id"]),
      {:ok, origin_id} <- Server.ID.cast(origin_id),
      true <-
        NetworkHenforcer.valid_origin?(origin_id, gateway_id, destination_id)
        || :badorigin
    do
      validated_params = %{
        network_id: network_id,
        address: request.unsafe["address"],
        origin: origin_id
      }

      update_params(request, validated_params, reply: true)
    else
      :badorigin ->
        reply_error("bad_origin")
      _ ->
        bad_request()
    end
  end

  def check_permissions(request, _socket),
    do: {:ok, request}

  def handle_request(request, _socket) do
    network_id = request.params.network_id
    origin_id = request.params.origin
    address = request.params.address

    case NetworkPublic.browse(network_id, address, origin_id) do
      {:ok, web, relay} ->
        update_meta(request, %{web: web, relay: relay}, reply: true)

      {:error, %{message: reason}} ->
        reply_error(reason)
    end
  end

  render(request, _socket) do
    web = request.meta.web
    server_id = request.meta.relay.server_id

    [network_id, ip] = web.nip

    pftp_files =
      server_id
      |> PFTPPublic.list_files()
      |> PFTPPublic.render_list_files()

    type =
      if web.subtype do
        to_string(web.type) <> "_" <> to_string(web.subtype)
      else
        to_string(web.type)
      end

    data = %{
      content: web.content,
      type: type,
      meta: %{
        nip: [to_string(network_id), to_string(ip)],
        password: web.password,
        public: pftp_files
      }
    }

    {:ok, data}
  end
end
