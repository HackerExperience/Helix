import Helix.Websocket.Request

request Helix.Software.Websocket.Requests.Cracker.Bruteforce do

  alias HELL.IPv4
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Software.Henforcer.Software.Cracker, as: CrackerHenforcer
  alias Helix.Software.Public.File, as: FilePublic

  def check_params(request, socket) do
    with \
      {:ok, network_id} <-
        Network.ID.cast(request.unsafe["network_id"]),
      true <- IPv4.valid?(request.unsafe["ip"]),
      {:ok, bounces} = cast_bounces(request.unsafe["bounces"]),
      true <- socket.assigns.meta.access_type == :local || :bad_attack_src
    do
      params = %{
        bounces: bounces,
        network_id: network_id,
        ip: request.unsafe["ip"]
      }

      update_params(request, params, reply: true)
    else
      :bad_attack_src ->
        reply_error("bad_attack_src")
      _ ->
        bad_request()
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
        reply_error(reason)
    end
  end

  def handle_request(request, _socket) do
    network_id = request.params.network_id
    ip = request.params.ip
    bounces = request.params.bounces
    cracker = request.meta.cracker
    gateway = request.meta.gateway
    target = request.meta.target

    bruteforce =
      FilePublic.bruteforce(cracker, gateway, target, network_id, ip, bounces)

    case bruteforce do
      {:ok, process} ->
        update_meta(request, %{process: process}, reply: true)

      # HACK: Workaround for https://github.com/elixir-lang/elixir/issues/6426
      error = {_, m} ->
        if Map.has_key?(m, :message) do
          error
        else
          internal_error()
        end
      # error = {:error, %{message: _}} ->
      #   error
      # _ ->
      #   {:error, %{message: "internal"}}
    end
  end

  render_process()

  defp cast_bounces(bounces) when is_list(bounces),
    do: {:ok, Enum.map(bounces, &(Server.ID.cast!(&1)))}
  defp cast_bounces(_),
    do: :error
end
