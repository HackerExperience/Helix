import Helix.Websocket.Request

request Helix.Server.Websocket.Requests.SetHostname do

  def check_params(request, _socket) do
    with \
      true <- not is_nil(request.unsafe["hostname"]),
      {:ok, hostname} <- validate_input(request.unsafe["hostname"], :hostname)
    do
      update_params(request, %{hostname: hostname}, reply: true)
    else
      _ ->
        bad_request()
    end
  end

  def check_permissions(request, _socket) do
    {:ok, request}
  end

  def handle_request(request, _socket) do
    {:ok, request}
  end

  def reply(request, _socket) do
    {:ok, %{data: :ronaldo}}
  end
end
