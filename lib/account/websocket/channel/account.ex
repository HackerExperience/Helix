import Helix.Websocket.Channel

channel Helix.Account.Websocket.Channel.Account do
  @moduledoc """
  Channel to notify an user of an action that affects them.
  """

  alias Helix.Account.Websocket.Channel.Account.Join, as: AccountJoin
  alias Helix.Account.Websocket.Channel.Account.Requests.Bootstrap,
    as: BootstrapRequest
  alias Helix.Account.Websocket.Channel.Account.Requests.EmailReply,
    as: EmailReplyRequest
  alias Helix.Account.Websocket.Channel.Account.Requests.Logout,
    as: LogoutRequest

  join _, AccountJoin

  topic "bootstrap", BootstrapRequest

  @doc """
  Replies to a Storyline email.

  Params:
    *reply_id: Reply identifier.

  Returns:
    %{}

  Errors:
  - "not_in_step" - Player is not currently in any mission.
  - "reply_not_found" - The given reply ID is not valid, may be locked or not
    exist within the current step email.
  """
  topic "email.reply", EmailReplyRequest

  @doc """
  Logs out from the channel.

  Params: nil

  Returns: nil

  **Channel will be closed**

  Errors:
  - internal
  """
  topic "account.logout", LogoutRequest

  @doc """
  Intercepts and handles outgoing events.
  """
  event_handler "event"
end
