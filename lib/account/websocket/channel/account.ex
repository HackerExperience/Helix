import Helix.Websocket.Channel

channel Helix.Account.Websocket.Channel.Account do
  @moduledoc """
  Channel to notify an user of an action that affects them.
  """

  alias Helix.Account.Websocket.Channel.Account.Join, as: AccountJoin
  alias Helix.Account.Websocket.Requests.Bootstrap, as: BootstrapRequest
  alias Helix.Account.Websocket.Requests.Logout, as: LogoutRequest
  alias Helix.Client.Websocket.Requests.Action, as: ClientActionRequest
  alias Helix.Client.Websocket.Requests.Setup, as: ClientSetupProxyRequest
  alias Helix.Network.Websocket.Requests.Bounce.Create, as: BounceCreateRequest
  alias Helix.Network.Websocket.Requests.Bounce.Update, as: BounceUpdateRequest
  alias Helix.Network.Websocket.Requests.Bounce.Remove, as: BounceRemoveRequest
  alias Helix.Software.Websocket.Requests.Virus.Collect, as: VirusCollectRequest
  alias Helix.Story.Websocket.Requests.Email.Reply, as: EmailReplyRequest
  alias Helix.Universe.Bank.Websocket.Requests.CreateAccount,
    as: BankAccountCreateRequest

  @doc """
  Joins the Account channel.

  Params: none

  Returns: AccountBootstrap

  Errors:
  - access_denied: Trying to connect to an account that isn't the one
    authenticated on the socket.
  + base errors
  """
  join "account:" <> _, AccountJoin

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
  Notifies the backend that `action` has been performed by the player.

  Params:
    *action: Action performed by the player. [0]

  Returns: :ok

  Errors:
  - "bad_action": The given `action` is not valid. See [0].
  + base errors

  Notes:
    [0] - List of all possible actions can be found at `ClientModel`.
  """
  topic "client.action", ClientActionRequest

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
  Collects money off of active viruses.

  Params:
    *gateway_id: Which gateway server is being used as origin.
    *viruses: List of viruses (`File.id`) that we should collect
    bounce_id: Which bounce should be used. If omitted, we assume none.
    atm_id: Which ATM the account_number belongs to. See [1] and [2].
    account_number: Which account should we send the money to. See [1] and [2].
    wallet: Which bitcoin address should we send the money to. See [1].

  [1] - Bank account or bitcoin wallet information may be optional if none of
    the viruses being collected will use them. For example, if the player is
    collecting money from 3 `spyware` viruses, no wallet is required. Similarly,
    if all viruses being collected are `miner`, no bank account is required. If
    there are both bitcoin-rewarding and cash-rewarding viruses, both payment
    information are required. This will be henforced!

  [2] - I don't always need bank account information (see [1]), but when I do, I
    require both `atm_id` and `account_number`. This will be henforced as well.

  Returns: :ok

  Events:
  - process_created: Emitted *for each virus* when VirusCollectProcess is
    created.
  - process_create_failed: Emitted when one or more of the underlying collect
    processes were not started due to lack of hardware resources.

  Errors:

  Henforcer:
  - payment_invalid: Required payment information is missing.
  - virus_not_active: One of the viruses at `viruses` isn't active
  - virus_not_found: One of the viruses at `viruses` wasn't found
  - bank_account_not_belongs: Given `{atm_id, account_number}` does not belong
  - bounce_not_belongs: Given `bounce_id` does not belong to the player
  - server_not_belongs: Given `gateway_id` does not belong to the player

  Input:
  - bad_virus: One of the entries at `viruses` is invalid.
  + base errors
  """
  topic "virus.collect", VirusCollectRequest

  @doc """
  Creates a BankAccount

  Params:
  *atm_id: ATM.id related to bank that player wants to create account in

  Returns: :ok

  Errors:

  Henforcer:
  - atm_not_a_bank: Given `atm_id` is not a bank

  Input:
  + base errors
  """
  topic "bank.createacc", BankAccountCreateRequest

  @doc """
  Intercepts and handles outgoing events.
  """
  event_handler "event"
end
