import Helix.Websocket.Request

request Helix.Universe.Bank.Websocket.Requests.Logout do

  alias Helix.Event
  alias Helix.Websocket

  alias Helix.Universe.Bank.Event.Bank.Account.Logout,
    as: BankAccountLogoutEvent
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  def check_params(request, _socket),
    do: reply_ok(request)

  def check_permissions(request, _socket),
    do: reply_ok(request)

  def handle_request(request, socket) do
    atm_id = socket.assigns.atm_id
    account_number = socket.assigns.account_number
    account = BankQuery.fetch_account(atm_id, account_number)

    entity_id = socket.assigns.gateway.entity_id

    events =
      [BankAccountLogoutEvent.new(account, entity_id)]

    socket
    |> Websocket.id()
    |> Helix.Endpoint.broadcast("disconnect", %{})

    Event.emit(events)

    reply_ok(request)
  end

  def reply(_request, _socket),
    do: {:stop, :shutdown}
end
