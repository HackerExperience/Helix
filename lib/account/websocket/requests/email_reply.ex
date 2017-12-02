import Helix.Websocket.Request

request Helix.Account.Websocket.Requests.EmailReply do
  @moduledoc """
  Implementation of the `EmailReply` request, which allows the player to send
  an (storyline) email reply to the Contact (story character)
  """

  alias Helix.Story.Public.Story, as: StoryPublic

  def check_params(request, _socket) do
    with \
      true <- is_binary(request.unsafe["reply_id"])
    do
      params = %{
        reply_id: request.unsafe["reply_id"]
      }

      update_params(request, params, reply: true)
    else
      _ ->
        bad_request(request)
    end
  end

  @doc """
  Permissions whether that reply is valid within the player's current context
  are checked at StoryPublic- and StoryAction-level
  """
  def check_permissions(request, _socket),
    do: reply_ok(request)

  def handle_request(request, socket) do
    entity_id = socket.assigns.entity_id
    reply_id = request.params.reply_id

    case StoryPublic.send_reply(entity_id, reply_id) do
      :ok ->
        reply_ok(request)
      {:error, %{message: msg}} ->
        reply_error(request, msg)
    end
  end

  render_empty()
end
