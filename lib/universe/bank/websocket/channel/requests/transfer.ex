import Helix.Websocket.Request

request Helix.Universe.Bank.Websocket.Requests.Transfer do
  @moduledoc """
  BankTransferRequest is used when the player transfer money from an account to other.

  It Returns :ok or :error
  """

  alias HELL.IPv4
  alias Helix.Account.Query.Account, as: AccountQuery
  alias Helix.Network.Model.Network
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.Bank.Henforcer.Bank, as: BankHenforcer
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery
  alias Helix.Universe.Bank.Public.Bank, as: BankPublic

  def check_params(request, _socket) do
    with \
      receiving_bank_acc <- request.unsafe["to_acc"],
      {:ok, receiving_bank_acc} <- BankAccount.cast(receiving_bank_acc),
      {:ok, network_id} <- Network.ID.cast(request.unsafe["to_bank_net"]),
      {:ok, ip} <- IPv4.cast(request.unsafe["to_bank_ip"]),
      {:ok, password} <- validate_input(request.unsafe["password"], :password),
      amount <- request.unsafe["amount"],
      {true, amount} <- (fn amount -> {amount > 0, amount} end).(amount)
    do
      params =
        %{
          bank_account: receiving_bank_acc,
          bank_ip: ip,
          bank_net: network_id,
          password: password,
          amount: amount
        }
      update_params(request, params, reply: true)
    else
      _ ->
        bad_request(request)
    end
  end

  def check_permissions(request, socket) do
    nip = {request.params.bank_net, request.params.bank_ip}
    atm_id = socket.assigns.atm_id
    account_number = socket.assigns.account_number
    sending_acc = {socket.assigns.atm_id, socket.assigns.account_number}
    receiving_acc = request.params.bank_account
    amount = request.params.amount
    password = request.params.password
    gateway_id = socket.assigns.gateway.server_id
    account_id = socket.assigns.account_id

    with \
      {true, relay} <-
        BankHenforcer.can_transfer?(
          nip,
          receiving_acc,
          sending_acc,
          amount,
          password
          ),
      amount = relay.amount,
      to_account = relay.to_account
    do
      meta =
        %{
          to_account: to_account,
          from_account: BankQuery.fetch_account(atm_id, account_number),
          amount: amount,
          started_by: AccountQuery.fetch(account_id),
          gateway: ServerQuery.fetch(gateway_id)
        }

      update_meta(request, meta, reply: true)
    else
      {false, reason, _} ->
        reply_error(request, reason)
      _ ->
        bad_request(request)
    end
  end

  def handle_request(request, socket) do
    to_account = request.meta.to_account
    from_account = request.meta.from_account
    amount = request.meta.amount
    started_by = request.meta.started_by
    relay = request.relay
    gateway = request.meta.gateway
    tunnel = socket.assigns.tunnel

    transfer =
      BankPublic.transfer(
        from_account,
        to_account,
        amount,
        started_by,
        gateway,
        tunnel,
        relay
        )

    case transfer do
      {:ok, process} ->
        update_meta(request, %{process: process}, reply: true)

      {:error, reason} ->
        reply_error(request, reason)
    end
  end

  render_empty()

end
