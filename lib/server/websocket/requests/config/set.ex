import Helix.Websocket.Request

request Helix.Server.Websocket.Requests.Config.Set do

  alias Helix.Websocket.Requestable
  alias Helix.Server.Websocket.Requests.Utils.Config, as: ConfigUtils

  def check_params(request, socket) do
    keys =
      Enum.reduce(request.unsafe, [], fn {key, _}, acc ->
        if key in ConfigUtils.valid_keys_str() do
          acc ++ [String.to_existing_atom(key)]
        else
          acc
        end
      end)

    backends = Enum.map(keys, fn key -> {key, ConfigUtils.get_backend(key)} end)

    sub_requests =
      backends
      |> Enum.map(fn {key, backend} ->
        req_params = request.unsafe[to_string(key)]

        req =
          backend
          |> apply(:new, [req_params, socket])
          |> Map.replace(:relay, request.relay)

        {key, req}
      end)

    sub_requests
    |> Enum.map(fn {key, sub_request} ->
        {key, Requestable.check_params(sub_request, socket)}
      end)
    |> parse_responses()
    |> reply_responses(request)
  end

  def check_permissions(request, socket) do
    request.meta.sub_requests
    |> Enum.map(fn {key, sub_request} ->
        {key, Requestable.check_permissions(sub_request, socket)}
      end)
    |> parse_responses()
    |> reply_responses(request)
  end

  def handle_request(request, socket) do
    request.meta.sub_requests
    |> Enum.map(fn {key, sub_request} ->
        {key, Requestable.handle_request(sub_request, socket)}
      end)
    |> parse_responses()
    |> reply_responses(request)
  end

  render_empty()

  defp parse_responses(responses) do
    acc0 = {%{}, %{}}

    {requests, errors} =
      Enum.reduce(responses, acc0, fn {key, response}, {req_acc, error_acc} ->
        case response do
          {:ok, req} ->
            {Map.put(req_acc, key, req), error_acc}

          {:error, %{message: reason}, _} ->
            {req_acc, Map.put(error_acc, key, reason)}
        end
      end)

    if Enum.empty?(errors) do
      {:ok, requests}
    else
      {:error, errors}
    end
  end

  defp reply_responses({:ok, requests}, request),
    do: update_meta(request, %{sub_requests: requests}, reply: true)
  defp reply_responses({:error, errors}, request),
    do: reply_error(request, errors, ready: true)
end
