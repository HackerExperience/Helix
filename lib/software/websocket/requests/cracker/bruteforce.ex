import Helix.Websocket.Request

request Helix.Software.Websocket.Requests.Cracker.Bruteforce do

  alias HELL.IPv4
  alias Helix.Network.Henforcer.Bounce, as: BounceHenforcer
  alias Helix.Network.Model.Network
  alias Helix.Software.Henforcer.Software.Cracker, as: CrackerHenforcer
  alias Helix.Software.Public.File, as: FilePublic

  # HACK for elixir-lang issue #6577
  @dialyzer {:nowarn_function, handle_request: 2}

  def check_params(request, socket) do
    with \
      {:ok, network_id} <-
        Network.ID.cast(request.unsafe["network_id"]),
      true <- IPv4.valid?(request.unsafe["ip"]),
      {:ok, bounce_id} <- validate_bounce(request.unsafe["bounce_id"]),
      true <- socket.assigns.meta.access == :local || :bad_attack_src
    do
      params = %{
        bounce_id: bounce_id,
        network_id: network_id,
        ip: request.unsafe["ip"]
      }

      update_params(request, params, reply: true)
    else
      :bad_attack_src ->
        reply_error(request, "bad_attack_src")
      _ ->
        bad_request(request)
    end
  end

  def check_permissions(request, socket) do
    network_id = request.params.network_id
    source_id = socket.assigns.gateway.server_id
    entity_id = socket.assigns.entity_id
    bounce_id = request.params.bounce_id
    ip = request.params.ip

    with \
      {true, r1} <- BounceHenforcer.can_use_bounce?(entity_id, bounce_id),
      {true, r2} <-
        CrackerHenforcer.can_bruteforce?(entity_id, source_id, network_id, ip)
    do
      meta = %{
        bounce: r1.bounce,
        gateway: r2.gateway,
        target: r2.target,
        cracker: r2.cracker
      }

      update_meta(request, meta, reply: true)

    else
      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  def handle_request(request, _socket) do
    network_id = request.params.network_id
    ip = request.params.ip
    bounce = request.meta.bounce
    cracker = request.meta.cracker
    gateway = request.meta.gateway
    target = request.meta.target
    relay = request.relay

    bruteforce =
      FilePublic.bruteforce(
        cracker, gateway, target, {network_id, ip}, bounce, relay
      )

    case bruteforce do
      {:ok, process} ->
        update_meta(request, %{process: process}, reply: true)

      {:error, reason} ->
        reply_error(request, reason)

      _ ->
        {:error, %{message: "internal"}}
    end
  end

  render_empty()
end
