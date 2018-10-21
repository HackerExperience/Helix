import Helix.Websocket.Request

request Helix.Log.Websocket.Requests.Paginate do

  alias Helix.Log.Model.Log
  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Log.Public.Index, as: LogIndex

  @default_total 20
  @max_total 100

  def check_params(request, _socket) do
    with {:ok, log_id} <- Log.ID.cast(request.unsafe["log_id"]) do
      params = %{
        log_id: log_id,
        total: get_total(request.unsafe["total"])
      }

      update_params(request, params, reply: true)
    else
      _ ->
        bad_request(request)
    end
  end

  defp get_total(total) when not is_integer(total),
    do: @default_total
  defp get_total(total) when total <= 0,
    do: @default_total
  defp get_total(total) when total >= @max_total,
    do: @max_total
  defp get_total(total),
    do: total

  def check_permissions(request, _socket),
    do: reply_ok(request)

  def handle_request(request, socket) do
    server_id = socket.assigns.destination.server_id
    log_id = request.params.log_id
    total = request.params.total

    logs = LogQuery.paginate_logs_on_server(server_id, log_id, total)

    update_meta(request, %{logs: logs}, reply: true)
  end

  render(request, _socket) do
    logs = Enum.map(request.meta.logs, &LogIndex.render_log/1)

    {:ok, logs}
  end
end
