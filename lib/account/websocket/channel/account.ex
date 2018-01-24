import Helix.Websocket.Channel

channel Helix.Account.Websocket.Channel.Account do
  @moduledoc """
  Channel to notify an user of an action that affects them.
  """

  alias Helix.Account.Websocket.Channel.Account.Join, as: AccountJoin
  alias Helix.Account.Websocket.Requests.Bootstrap, as: BootstrapRequest
  alias Helix.Account.Websocket.Requests.EmailReply, as: EmailReplyRequest
  alias Helix.Account.Websocket.Requests.Logout, as: LogoutRequest
  alias Helix.Client.Websocket.Requests.Setup, as: ClientSetupProxyRequest
  alias Helix.Network.Websocket.Requests.Bounce.Create, as: BounceCreateRequest

  @doc """
  Joins the Account channel.

  Params: none

  Returns: AccountBootstrap

  Errors:
  - access_denied: Trying to connect to an account that isn't the one
    authenticated on the socket.
  + base_errors
  """
  join _, AccountJoin

  @doc """
  Forces a bootstrap to happen. It is the exact same operation ran during join.
  Useful if the client wants to force a resynchronization of the local data.

  Params: none

  Returns: AccountBootstrap

  Errors:
  + base errors
  """
  topic "bootstrap", BootstrapRequest

  @doc """
  Saves the Client's SetupPage progress.

  Params:
    *pages: List of page ids

  Returns: :ok

  Errors:
  - "request_not_implemented_for_client" - The registered client does not
    implements that request.
  + base_errors
  """
  topic "client.setup", ClientSetupProxyRequest

  @doc """
  Replies to a Storyline email.

  Params:
    *reply_id: Reply identifier.

  Returns: :ok

  Errors:
  - "not_in_step" - Player is not currently in any mission.
  - "reply_not_found" - The given reply ID is not valid, may be locked or not
    exist within the current step email.
  """
  topic "email.reply", EmailReplyRequest

  @doc """
  Logs out from the channel.

  Params: nil

  Returns: :ok

  **Channel will be closed**

  Errors:
  - internal
  """
  topic "account.logout", LogoutRequest

  @doc """
  Creates a new bounce.

  Params:
    *name: Bounce name.
    *links: Links that will exist on the bounce. The received order will be the
    bounce order. Must contain `network_id`, `ip` and `password`.

  Example:
    %{
      "name" => "bounce_name",
      "links" => [
        %{"network_id" => "::", "ip" => "1.2.3.4", "password" => "hunter2"},
        %{"network_id" => "::", "ip" => "4.3.2.1", "password" => "*******"}
      ]
    }

  Returns: :ok

  Events:
  - bounce_created: Emitted when bounce creation is successful
  - bounce_create_failed: Emitted when bounce creation fail for any reason

  Errors:

  Henforcer:
  - nip_not_found: One of the entries of `links` was not found
  - bounce_no_access: One of the entries of `links` failed to authenticate

  Input validation:
  - bad_entry: One of the entries of `links` has an invalid format.
  + base errors
  """
  topic "bounce.create", BounceCreateRequest

  @doc """
  Intercepts and handles outgoing events.
  """
  event_handler "event"
end
