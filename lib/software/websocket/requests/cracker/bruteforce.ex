import Helix.Websocket.Request

request Helix.Software.Websocket.Requests.Cracker.Bruteforce do

  alias HELL.IPv4
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Software.Henforcer.Software.Cracker, as: CrackerHenforcer
  alias Helix.Software.Public.File, as: FilePublic

  # HACK for elixir-lang issue #6577
  @dialyzer {:nowarn_function, handle_request: 2}

  def check_params(request, socket) do
    with \
      {:ok, network_id} <-
        Network.ID.cast(request.unsafe["network_id"]),
      true <- IPv4.valid?(request.unsafe["ip"]),
      {:ok, bounces} = cast_bounces(request.unsafe["bounces"]),
      true <- socket.assigns.meta.access == :local || :bad_attack_src
    do
      params = %{
        bounces: bounces,
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
    ip = request.params.ip

    can_bruteforce =
      CrackerHenforcer.can_bruteforce?(entity_id, source_id, network_id, ip)

    case can_bruteforce do
      {true, relay} ->
        meta = %{
          gateway: relay.gateway,
          target: relay.target,
          cracker: relay.cracker
        }

        update_meta(request, meta, reply: true)

      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  def handle_request(request, _socket) do
    network_id = request.params.network_id
    ip = request.params.ip
    bounces = request.params.bounces
    cracker = request.meta.cracker
    gateway = request.meta.gateway
    target = request.meta.target
    relay = request.relay

    bruteforce =
      FilePublic.bruteforce(
        cracker, gateway, target, {network_id, ip}, bounces, relay
      )

    case bruteforce do
      {:ok, process} ->
        update_meta(request, %{process: process}, reply: true)

      {false, reason, _} ->
        reply_error(request, reason)

      error = {:error, %{message: _}} ->
        error
      _ ->
        {:error, %{message: "internal"}}
    end
  end

  render_empty()

  defp cast_bounces(bounces) when is_list(bounces),
    do: {:ok, Enum.map(bounces, &(Server.ID.cast!(&1)))}
  defp cast_bounces(_),
    do: :error
end
