import Helix.Websocket.Request

request Helix.Story.Websocket.Requests.Email.Reply do
  @moduledoc """
  Implementation of the `EmailReply` request, which allows the player to send
  an (storyline) email reply to the Contact (story character)
  """

  alias Helix.Story.Public.Story, as: StoryPublic

  def check_params(request, _socket) do
    with \
      true <- is_binary(request.unsafe["reply_id"]),
      {:ok, contact_id} <- cast_contact(request.unsafe["contact_id"])
    do
      params = %{
        reply_id: request.unsafe["reply_id"],
        contact_id: contact_id
      }

      update_params(request, params, reply: true)
    else
      {:error, reason = :bad_contact} ->
        reply_error(request, reason)

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
    contact_id = request.params.contact_id

    case StoryPublic.send_reply(entity_id, contact_id, reply_id) do
      :ok ->
        reply_ok(request)

      {:error, reason} ->
        reply_error(request, reason)
    end
  end

  render_empty()

  defp cast_contact(contact_id) do
    try do
      {:ok, String.to_existing_atom(contact_id)}
    rescue
      _ ->
        {:error, :bad_contact}
    end
  end

  defp get_error(:bad_step),
    do: "not_in_step"
end
