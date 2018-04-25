import Helix.Websocket.Request

request Helix.Universe.Bank.Websocket.Requests.CloseAccount do
  @moduledoc """
  BankCloseAccountRequest is used when player wants to close the
  BankAccount.

  It Returs :ok or :error
  """
  alias Helix.Universe.Bank.Henforcer.Bank, as: BankHenforcer
  alias Helix.Universe.Bank.Public.Bank, as: BankPublic
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  def check_params(request, _socket) do
    reply_ok(request)
  end

  @doc """
  Checks if player can close BankAccount, most of logic is delegated to
  BankHenforcer.can_close?/2
  """
  def check_permissions(request, socket) do
    atm_id = socket.assigns.atm_id
    account_number = socket.assigns.account_number
    with \
      {true, _relay} <- BankHenforcer.can_close?(atm_id, account_number)
    do
      reply_ok(request)
    else
      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  def handle_request(request, socket) do
    atm_id = socket.assigns.atm_id
    account_number = socket.assigns.account_number
    bank_account = BankQuery.fetch_account(atm_id, account_number)
    close_account = BankPublic.close_account(bank_account)

    case close_account do
      :ok ->
        reply_ok(request)
      {:error, reason} ->
        reply_error(request, reason)
    end
  end
  render_empty()
end
