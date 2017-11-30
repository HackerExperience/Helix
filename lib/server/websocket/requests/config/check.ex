import Helix.Websocket.Request

request Helix.Server.Websocket.Requests.Config.Check do

  alias Helix.Websocket.Requestable
  alias Helix.Server.Websocket.Requests.Utils.Config, as: ConfigUtils

  def check_params(request, socket) do
    with \
      true <- request.unsafe["key"] in ConfigUtils.valid_keys_str(),
      key = String.to_existing_atom(request.unsafe["key"])
    do
      backend = ConfigUtils.get_backend(key)

      sub_request =
        backend
        |> apply(:new, [request.unsafe["value"], socket])
        |> Map.replace(:relay, request.relay)

      with {:ok, sub_req} <- Requestable.check_params(sub_request, socket) do
        update_meta(request, %{sub_request: sub_req}, reply: true)
      end
    else
      _ ->
        bad_request()
    end
  end

  @doc """
  All ConfigCheck requests consists of actually running what would be the
  permission of ConfigSet. So here we assume all requests are valid, and we run
  the permission at `handle_request`. Because, in reality, ConfigCheck's purpose
  is to call the corresponding henforcer, so that should be on `handle_request`.
  """
  def check_permissions(request, _socket),
    do: {:ok, request}

  def handle_request(request, socket) do
    sub_request = request.meta.sub_request

    with {:ok, sub_req} <- Requestable.check_permissions(sub_request, socket) do
      update_meta(request, %{sub_request: sub_req}, reply: true)
    end
  end

  render_empty()
end
