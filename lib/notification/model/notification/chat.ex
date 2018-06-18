defmodule Helix.Notification.Model.Notification.Chat do
  @moduledoc """
  TODO: Chat notifications

  Implementation suggestion:

  Have the `notifications_chat` table reference to an external `chat_id`. The
  external chat data has all required information, including `last_message` and
  `last_sender`. This way, the notification table does not need be updated on
  every new message sent.
  """
end
