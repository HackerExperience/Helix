defmodule Helix.Account.Websocket.Channel.Account.Requests.EmailReply do
  @moduledoc """
  Implementation of the `EmailReply` request, which allows the player to send
  an (storyline) email reply to the Contact (story character)
  """

  require Helix.Websocket.Request

  Helix.Websocket.Request.register()

  defimpl Helix.Websocket.Requestable do

    alias Helix.Websocket.Utils, as: WebsocketUtils
    alias Helix.Story.Public.Story, as: StoryPublic

    def check_params(request, _socket) do
      with \
        true <- is_binary(request.unsafe["reply_id"])
      do
        params = %{
          reply_id: request.unsafe["reply_id"]
        }

        {:ok, %{request| params: params}}
      else
        _ ->
          {:error, %{message: "bad_request"}}
      end
    end

    @doc """
    Permissions whether that reply is valid within the player's current context
    are checked at StoryPublic- and StoryAction-level
    """
    def check_permissions(request, _socket),
      do: {:ok, request}

    def handle_request(request, socket) do
      entity_id = socket.assigns.entity_id
      reply_id = request.params.reply_id

      case StoryPublic.send_reply(entity_id, reply_id) do
        :ok ->
          {:ok, request}
        error ->
          error
      end
    end

    def reply(_request, socket),
      do: WebsocketUtils.reply_ok(%{}, socket)
  end
end
