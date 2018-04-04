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
  #alias Helix.Universe.Bank.Requests.Bootstrap, as: BootstrapRequest
  #alias Helix.Universe.Bank.Requests.Transfer, as: BankTransfer

  @doc """
    Join the Bank Channel

    Topic: "bank:<account_number>@<atm_id>"

    Params:
    - *password: Target account password.

    Returns: BankAccountBootstrap

    Errors:

    Henforcer:
    - "password_invalid": Password is invalid.

    Input:
    - "bank_account_non_ecziste"
    + base errors
  """

  join "bank:" <> _, BankJoin

  @doc """
  Starts a financial transaction.

  Params:
    - *to_bank_ip: Receiving bank ip.
    - *to_bank_net: Receiving bank network.
    - *to_acc: Account number that receives money.
    - *password: Sending Bank Account password.
    - *value: Amount of money that is being sent.

  Returns: :ok

  Errors:
  - "insufficient_money"
  - "receiving_bank_not_found"
  - "receiving_account_not_found"
  - "sending_bank_not_found"
  - "sending_account_not_found"
  - "receiving_bank_is_not_a_bank"
  - "sending_bank_is_not_a_bank"
  """
  # topic "bank.transfer", BankTransfer

  @doc """
  Forces a bootstrap to happen. It is the exact same operation ran during join.
  Useful if the client wants to force a resynchronization of the local data.

  Params: none

  Returns: BankBootstrap

  Errors:
  + base errors
  """
  # topic "bootstrap", BootstrapRequest


  event_handler "event"

  def terminate(_reason, _socket) do

  end
end
