import Helix.Websocket.Request

request Helix.Log.Websocket.Requests.Recover do
  @moduledoc """
  `LogRecoverRequest` is called when the player wants to recover a log. It may
  either be a `global` recovery, in which case a recoverable log is randomly
  selected from all logs within the server, or it may be a `custom` recovery,
  in which case a specific log to be recovered is defined by the player.
  """

  import HELL.Macros

  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Log.Henforcer.Log.Recover, as: LogRecoverHenforcer
  alias Helix.Log.Model.Log
  alias Helix.Log.Public.Recover, as: RecoverPublic

  def check_params(request, socket) do
    case request.unsafe["method"] do
      "global" ->
        check_params_global(request, socket)

      "custom" ->
        check_params_custom(request, socket)

      _ ->
        reply_error(request, "bad_method")
    end
  end

  defp check_params_global(request, _socket) do
    with \
      true <- is_nil(request.unsafe["log_id"])
    do
      update_params(request, %{method: :global}, reply: true)
    else
      _ ->
        bad_request(request)
    end
  end

  defp check_params_custom(request, _socket) do
    with \
      {:ok, log_id} <- Log.ID.cast(request.unsafe["log_id"])
    do
      params = %{method: :custom, log_id: log_id}

      update_params(request, params, reply: true)
    else
      _ ->
        bad_request(request)
    end
  end

  def check_permissions(request = %{params: %{method: :global}}, socket) do
    gateway_id = socket.assigns.gateway.server_id

    case LogRecoverHenforcer.can_recover_global?(gateway_id) do
      {true, relay} ->
        meta = %{gateway: relay.gateway, recover: relay.recover}
        update_meta(request, meta, reply: true)

      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  def check_permissions(request = %{params: %{method: :custom}}, socket) do
    log_id = request.params.log_id
    gateway_id = socket.assigns.gateway.server_id
    target_id = socket.assigns.destination.server_id

    can_recover? =
      LogRecoverHenforcer.can_recover_custom?(log_id, gateway_id, target_id)

    case can_recover? do
      {true, relay} ->
        meta = %{gateway: relay.gateway, recover: relay.recover, log: relay.log}
        update_meta(request, meta, reply: true)

      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  def handle_request(request, socket) do
    entity_id = socket.assigns.entity_id
    recover = request.meta.recover
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
      if request.params.method == :global do
        RecoverPublic.global(
          gateway, target, recover, entity_id, conn_info, relay
        )
      else
        log = request.meta.log

        RecoverPublic.custom(
          gateway, target, log, recover, entity_id, conn_info, relay
        )
      end
    end

    reply_ok(request)
  end

  render_empty()
end
