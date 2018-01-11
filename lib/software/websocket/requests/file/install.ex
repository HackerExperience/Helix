import Helix.Websocket.Request

request Helix.Software.Websocket.Requests.File.Install do

  import HELL.Macros

  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Software.Henforcer.File, as: FileHenforcer
  alias Helix.Software.Henforcer.Virus, as: VirusHenforcer
  alias Helix.Software.Model.File
  alias Helix.Software.Public.File, as: FilePublic

  alias Helix.Software.Process.File.Install, as: FileInstallProcess

  def check_params(request, _socket) do
    with {:ok, file_id} <- File.ID.cast(request.unsafe["file_id"]) do
      params = %{file_id: file_id}

      update_params(request, params, reply: true)
    else
      _ ->
        bad_request(request)
    end
  end

  def check_permissions(request, socket) do
    entity_id = socket.assigns.entity_id
    gateway_id = socket.assigns.gateway.server_id
    target_id = socket.assigns.destination.server_id
    file_id = request.params.file_id

    with \
      {true, r1} <- FileHenforcer.Install.can_install?(file_id, entity_id),
      {true, %{server: gateway}} <- ServerHenforcer.server_exists?(gateway_id),
      {true, %{server: target}} <- ServerHenforcer.server_exists?(target_id)
    do
      file = r1.file
      relay = Map.merge(r1, %{gateway: gateway, target: target})

      backend = FileInstallProcess.get_backend(file)
      check_permissions_backend(backend, request, relay)
    else
      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  defp check_permissions_backend(:virus, request, relay) do
    case VirusHenforcer.can_install?(relay.file, relay.entity) do
      {true, r2} ->
        meta =
          relay
          |> Map.merge(r2)
          |> Map.merge(%{backend: :virus})

        update_meta(request, meta, reply: true)

      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  def handle_request(request, socket) do
    file = request.meta.file
    gateway = request.meta.gateway
    target = request.meta.target
    backend = request.meta.backend
    network_id = socket.assigns.tunnel.network_id
    relay = request.relay

    hespawn fn ->
      FilePublic.install(file, gateway, target, backend, network_id, relay)
    end

    reply_ok(request)
  end

  render_empty()
end
