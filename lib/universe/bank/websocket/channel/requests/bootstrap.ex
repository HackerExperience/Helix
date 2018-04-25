import Helix.Websocket.Request

request Helix.Universe.Bank.Websocket.Requests.Bootstrap do
  @moduledoc """
  BankBootstrapRequest is used to allow the client to resync its local data
  with the Helix server.

  It returns the BankBootstrap, which is the exact same struct returned after
  joining a local or remote bank Channel.
  """
  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Henforcer.Bank, as: BankHenforcer
  alias Helix.Universe.Bank.Public.Bank, as: BankPublic

  def check_params(request, _socket) do
    reply_ok(request)
  end

  def check_permissions(request, _socket) do
    reply_ok(request)
  end

  def handle_request(request, socket) do
    atm_id = socket.assigns.atm_id
    account_number = socket.assigns.account_number
    bank_account = {atm_id, account_number}

    bootstrap =
      BankPublic.bootstrap(bank_account)

    update_meta(request, %{bootstrap: bootstrap}, reply: true)
  end

  render(request, _socket) do
    data = BankPublic.render_bootstrap(request.meta.bootstrap)

    {:ok, data}
  end
end
