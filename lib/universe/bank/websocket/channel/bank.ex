import Helix.Websocket.Channel

channel Helix.Universe.Bank.Websocket.Channel.Bank do
  @moduledoc """
  `BankChannel` handles incoming and outgoing messages between players and ]
  bank servers

  Base errors (applicable to all requests expected to replay something):

  - "bad_request" - One or more request params are invalid
  - "internal" - Something unexpected happened
  """
  alias Helix.Universe.Bank.Websocket.Channel.Bank.Join, as: BankJoin
  alias Helix.Universe.Bank.Websocket.Requests.Bootstrap, as: BootstrapRequest
  alias Helix.Universe.Bank.Websocket.Requests.Transfer, as: BankTransferRequest
  alias Helix.Universe.Bank.Websocket.Requests.CloseAccount,
    as: BankCloseAccountRequest
  alias Helix.Universe.Bank.Websocket.Requests.ChangePassword,
    as: BankChangePasswordRequest
  alias Helix.Universe.Bank.Websocket.Requests.RevealPassword,
    as: BankRevealPasswordRequest
  alias Helix.Universe.Bank.Websocket.Requests.Logout, as: LogoutRequest

  @doc """
    Join the Bank Channel

    Topic: "bank:<account_number>@<atm_id>"

    Params:
    *password: Target account password.

    Returns: BankAccountBootstrap

    Errors:

    Henforcer:
    - "password_invalid": Password is invalid.
    - "bank_account_not_found"

    Input:
    + base errors
  """

  join "bank:" <> _, BankJoin

  @doc """
  Starts a financial transaction.

  Params:
  *to_bank_ip: Receiving bank ip.
  *to_bank_net: Receiving bank network.
  *to_acc: Account number that receives money.
  *password: Sending Bank Account password.
  *value: Amount of money that is being sent.

  Returns: :ok

  Errors:

  Henforcer:
  - "atm_not_a_bank"
  - "bank_account_no_funds"
  - "bank_account_not_found"
  """
  topic "bank.transfer", BankTransferRequest

  @doc """
  Starts a password changing request

  Params: none

  Returns: :ok

  Errors:
  - internal

  Henforcer:
    - "bank_account_not_belongs"
  """
  topic "bank.changepass", BankChangePasswordRequest

  @doc """
  Closes a Logged in BankAccount.

  Params: none

  Returns: :ok

  Errors:
  - internal

  Henforcer:
  - "bank_account_not_belongs"
  """
  topic "bank.closeacc", BankCloseAccountRequest

  @doc """
  Starts a RevealPasswordProcess.

  Params:
  *token: token.id for logged in account

  Henforcer:
  - "token_not_belongs"
  - "token_expired"
  - "token_not_found"
  """
  topic "bank.reveal", BankRevealPasswordRequest

  @doc """
  Forces a bootstrap to happen. It is the exact same operation ran during join.
  Useful if the client wants to force a resynchronization of the local data.

  Params: none

  Returns: BankBootstrap

  Errors:
  + base errors
  """
  topic "bootstrap", BootstrapRequest

  @doc """
  Logs out from the channel

  Params: nil

  Returns: :ok

  **Channel will be closed**

  Errors:
  - internal
  """
  topic "bank.logout", LogoutRequest

  event_handler "event"

  def terminate(_reason, _socket) do
    :ok
  end
end
