import Helix.Websocket.Request

request Helix.Universe.Bank.Websocket.Requests.ChangePassword do
  @moduledoc """
  BankChangePasswordRequest is used when the player wants to change
  he's BankAccount's password.

  It Returns :ok or :error
  """
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.Bank.Public.Bank, as: BankPublic
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery
  alias Helix.Universe.Bank.Henforcer.Bank, as: BankHenforcer

  def check_params(request, _socket) do
    reply_ok(request)
  end

  @doc """
  Checks if Logged player owns the BankAccount, most of logic is delegated to
  BankHenforcer.owns_account?/2
  """
  def check_permissions(request, socket) do
    entity = EntityQuery.fetch(socket.assigns.gateway.entity_id)
    atm_id = socket.assigns.atm_id
    account_number = socket.assigns.account_number
    bank_account = BankQuery.fetch_account(atm_id, account_number)
    with \
      {true, relay} <- BankHenforcer.owns_account?(entity, bank_account)
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
    account = BankQuery.fetch_account(atm_id, account_number)
    atm = ServerQuery.fetch(atm_id)
    gateway = ServerQuery.fetch(socket.assigns.gateway.server_id)
    password_change =
      BankPublic.change_password(account, gateway, atm, request.relay)

    case password_change do
      {:ok, process} ->
        update_meta(request, %{process: process}, reply: true)
      {:error, reason} ->
        reply_error(request, reason)
    end
  end

  render_empty()
end
