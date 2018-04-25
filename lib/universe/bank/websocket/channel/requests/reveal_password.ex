import Helix.Websocket.Request

request Helix.Universe.Bank.Websocket.Requests.RevealPassword do
  @moduledoc """
  This request is called when the player wants to get the password for
  a bank account which he's logged in by using a token
  """

  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.Bank.Henforcer.Bank, as: BankHenforcer
  alias Helix.Universe.Bank.Public.Bank, as: BankPublic
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  def check_params(request, _socket) do
    # Check if token value has the correct format
    with \
      {:ok, token} <- validate_input(request.unsafe["token"], :token)
    do
      update_params(request, %{token: token}, reply: true)
    else
      _ ->
        bad_request(request)
    end
  end

  @doc """
  Verifies the permission for the password reveal. Most of the perimssion
  logic has been delegated to `BankHenforcer.token_valid?/2`

  This is where we the token.account_number, token.atm_id is the same
  as the logged in bank account and if expiration date is not expired
  """
  def check_permissions(request, socket) do
    token = request.params.token
    atm_id = socket.assigns.atm_id
    account_number = socket.assigns.account_number
    bank_account = BankQuery.fetch_account(atm_id, account_number)
    case BankHenforcer.token_valid?(bank_account, token) do
      {true, relay} ->
        token = relay.token
        update_meta(request, %{token: token}, reply: true)
      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  def handle_request(request, socket) do
    atm_id = socket.assigns.atm_id
    account_number = socket.assigns.account_number
    bank_account = BankQuery.fetch_account(atm_id, account_number)
    token = request.meta.token.token_id
    gateway_id = socket.assigns.gateway.server_id
    gateway = ServerQuery.fetch(gateway_id)
    atm = ServerQuery.fetch(atm_id)
    relay = request.relay

    reveal_password =
      BankPublic.reveal_password(
        bank_account,
        token,
        gateway,
        atm,
        relay
        )

    case reveal_password do
      {:ok, process} ->
        update_meta(request, %{process: process}, reply: true)
      {:error, reason} ->
        reply_error(request, reason)
    end
  end

  render_empty()

end
