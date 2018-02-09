import Helix.Websocket.Channel

channel Helix.Account.Websocket.Channel.Account do
  @moduledoc """
  Channel to notify an user of an action that affects them.
  """

  alias Helix.Account.Websocket.Channel.Account.Join, as: AccountJoin
  alias Helix.Account.Websocket.Requests.Bootstrap, as: BootstrapRequest
  alias Helix.Account.Websocket.Requests.Logout, as: LogoutRequest
  alias Helix.Client.Websocket.Requests.Setup, as: ClientSetupProxyRequest
  alias Helix.Network.Websocket.Requests.Bounce.Create, as: BounceCreateRequest
  alias Helix.Network.Websocket.Requests.Bounce.Update, as: BounceUpdateRequest
  alias Helix.Network.Websocket.Requests.Bounce.Remove, as: BounceRemoveRequest
  alias Helix.Story.Websocket.Requests.Email.Reply, as: EmailReplyRequest

  @doc """
  Joins the Account channel.

  Params: none

  Returns: AccountBootstrap

  Errors:
  - access_denied: Trying to connect to an account that isn't the one
    authenticated on the socket.
  + base errors
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
  + base errors
  """
  topic "client.setup", ClientSetupProxyRequest

  @doc """
  Replies to a Storyline email.

  Params:
    *reply_id: Reply identifier.
    *contact_id: Which contact the reply is directed to.

  Returns: :ok

  Errors:
  - "bad_contact" - The given contact is invalid.
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
  - bounce_create_failed: Emitted when bounce creation failed for any reason.

  Errors:

  Henforcer:
  - nip_not_found: One of the entries of `links` was not found
  - bounce_no_access: One of the entries of `links` failed to authenticate

  Input validation:
  - bad_link: One of the entries of `links` has an invalid format.
  + base errors
  """
  topic "bounce.create", BounceCreateRequest

  @doc """
  Updates an existing bounce.

  Params:
    *bounce_id: Which bounce to update. Duh.
    name: Set a new name for the bounce.
    links: Set a new group of links that will be used for future bounces. Same
    type as the one at "bounce.create".

  NOTE: `name` and `links` are optional, but AT LEAST ONE of them must be set!

  Example:
    %{
      "bounce_id" => "::1",
      "name" => "new_name",
      "links" => [
        %{"network_id" => "::", "ip" => "8.8.8.8", "password" => "googol"}
      ]
    }

  Returns: :ok

  Events:
  - bounce_updated: Emitted when bounce update was successful.
  - bounce_update_failed: Emitted when bounce update failed for any reason.

  Errors:

  Henforcer:
  - bounce_not_belongs: Attempting to update a bounce that is not owned by you
  - nip_not_found: One of the entries of `links` was not found
  - bounce_no_access: One of the entries of `links` failed to authenticate
  - bounce_in_use: Bounce is currently in use. All tunnels using the bounce must
    be closed in order for it to be able to update its links.

  Input validation:
  - bad_link
  """
  topic "bounce.update", BounceUpdateRequest

  @doc """
  Removes an existing bounce.

  Params:
    *bounce_id: Which bounce to remove

  Returns: :ok

  Events:
  - bounce_removed: Emitted when bounce remove was successful.
  - bounce_remove_failed: Emitted when bounce remove failed for any reason.

  Errors:

  Henforcer:
  - bounce_not_belongs: Attempting to update a bounce that is not owned by you
  - bounce_in_use: Bounce is currently in use. All tunnels using the bounce must
    be closed in order for it to be able to update its links.

  Input:
  + base errors

  """
  topic "bounce.remove", BounceRemoveRequest

  @doc """
  Intercepts and handles outgoing events.
  """
  event_handler "event"
end
