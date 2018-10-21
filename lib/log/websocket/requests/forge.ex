import Helix.Websocket.Request

request Helix.Log.Websocket.Requests.Forge do
  @moduledoc """
  `LogForgeRequest` is called when the player wants to forge a log. The forge
  operation may either edit an existing log or create a new one.
  """

  import HELL.Macros

  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Log.Henforcer.Log.Forge, as: LogForgeHenforcer
  alias Helix.Log.Model.Log
  alias Helix.Log.Model.LogType
  alias Helix.Log.Public.Forge, as: ForgePublic

  def check_params(request, socket) do
    case request.unsafe["action"] do
      "create" ->
        check_params_create(request, socket)

      "edit" ->
        check_params_edit(request, socket)

      _ ->
        reply_error(request, "bad_action")
    end
  end

  defp check_params_create(request, _socket) do
    with \
      {:ok, log_info} <-
        cast_log_info(request.unsafe["log_type"], request.unsafe["log_data"])
    do
      params = %{action: :create, log_info: log_info}

      update_params(request, params, reply: true)
    else
      {:error, reason} ->
        reply_error(request, reason)
    end
  end

  defp check_params_edit(request, _socket) do
    with \
      {:ok, log_id} <- Log.ID.cast(request.unsafe["log_id"]),
      {:ok, log_info} <-
        cast_log_info(request.unsafe["log_type"], request.unsafe["log_data"])
    do
      params = %{action: :edit, log_id: log_id, log_info: log_info}

      update_params(request, params, reply: true)
    else
      {:error, reason} ->
        reply_error(request, reason)

      _ ->
        bad_request(request)
    end
  end

  def check_permissions(request = %{params: %{action: :create}}, socket) do
    gateway_id = socket.assigns.gateway.server_id

    case LogForgeHenforcer.can_create?(gateway_id) do
      {true, relay} ->
        meta = %{gateway: relay.gateway, forger: relay.forger}
        update_meta(request, meta, reply: true)

      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  def check_permissions(request = %{params: %{action: :edit}}, socket) do
    log_id = request.params.log_id
    gateway_id = socket.assigns.gateway.server_id
    target_id = socket.assigns.destination.server_id

    case LogForgeHenforcer.can_edit?(log_id, gateway_id, target_id) do
      {true, relay} ->
        meta = %{gateway: relay.gateway, forger: relay.forger, log: relay.log}
        update_meta(request, meta, reply: true)

      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  def handle_request(request, socket) do
    log_info = request.params.log_info
    forger = request.meta.forger
    gateway = request.meta.gateway
    relay = request.relay

    {target, conn_info} =
      if socket.assigns.meta.access == :local do
        {gateway, nil}
      else
        {
          ServerQuery.fetch(socket.assigns.destination.server_id),
          {socket.assigns.tunnel, socket.assigns.ssh}
        }
      end

    hespawn fn ->
      if request.params.action == :create do
        ForgePublic.create(
          gateway, target, log_info, forger, conn_info, relay
        )
      else
        entity_id = socket.assigns.entity_id
        log = request.meta.log

        ForgePublic.edit(
          gateway, target, log, log_info, forger, entity_id, conn_info, relay
        )
      end
    end

    reply_ok(request)
  end

  @spec cast_log_info(String.t, map) ::
    {:ok, Log.info}
    | {:error, :bad_log_type | :bad_log_data}
  defp cast_log_info(unsafe_log_type, unsafe_log_data) do
    with \
      {:ok, log_type} <- cast_existing_atom(unsafe_log_type),
      true <- LogType.exists?(log_type) || {:error, :log_type},
      {:ok, log_data} <- LogType.parse(log_type, unsafe_log_data)
    do
      {:ok, {log_type, log_data}}
    else
      {:error, :atom_not_found} ->
        {:error, :bad_log_type}

      {:error, :log_type} ->
        {:error, :bad_log_type}

      :error ->
        {:error, :bad_log_data}
    end
  end

  render_empty()
end
