import Helix.Websocket.Request

request Helix.Client.Websocket.Requests.Action do

  import HELL.Macros

  alias Helix.Client.Public.Client, as: ClientPublic
  alias Helix.Client.Web1.Model.Web1

  def check_params(request, socket) do
    with \
      true <-
        valid_action?(socket.assigns.client, request.unsafe["action"])
        || :bad_action,
      action = String.to_existing_atom(request.unsafe["action"])
    do
      update_params(request, %{action: action}, reply: true)
    else
      :bad_action ->
        reply_error(request, "bad_action")

      _ ->
        bad_request(request)
    end
  end

  defp valid_action?(client, action) do
    valid_actions_str =
      case client do
        :web1 ->
          Web1.valid_actions_str()

        _ ->
          []
      end

    Enum.member?(valid_actions_str, action)
  end

  def check_permissions(request, _socket),
    do: {:ok, request}

  def handle_request(request, socket) do
    entity_id = socket.assigns.entity_id
    client = socket.assigns.client
    action = request.params.action

    hespawn fn ->
      ClientPublic.broadcast_action(client, entity_id, action)
    end

    reply_ok(request)
  end

  render_empty()
end
