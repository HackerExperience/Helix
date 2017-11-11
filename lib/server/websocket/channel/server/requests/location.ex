import Helix.Websocket.Request

request Helix.Server.Websocket.Requests.Location do
  @moduledoc """
  Obviously TODO
  """

  def check_params(request, _socket) do
    with \
      {lat, _} <- Float.parse(request.unsafe["lat"]),
      {lon, _} <- Float.parse(request.unsafe["lon"])
    do
      update_params(request, %{lat: lat, lon: lon}, reply: true)
    else
      _ ->
        bad_request()
    end
  end

  def check_permissions(request, _socket) do
    # HACK: See `ConfigTest` (@ ServerRequests) for context
    if request.params.lon == 66.6 do
      reply_error("some_permission_error")
    else
      {:ok, request}
    end
  end

  def handle_request(request, _socket) do
    # HACK: See `ConfigTest` (@ ServerRequests) for context
    if request.params.lon == 66.7 do
      reply_error("some_uncommon_error")
    else
      {:ok, request}
    end
  end

  def reply(request, _socket) do
    {:ok, %{}}
  end
end
