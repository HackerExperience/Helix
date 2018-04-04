import Helix.Websocket.Join

join Helix.Universe.Bank.Websocket.Channel.Bank.Join do
  @moduledoc """
  Joinable implementation for the Bank channel
  """

  use Helix.Logger

  import HELL.Macros

  alias Helix.Websocket.Utils, as: WebsocketUtils
  alias Helix.Account.Model.Account
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Henforcer.Bank, as: BankHenforcer
  alias Helix.Universe.Bank.Public.Bank, as: BankPublic

  def check_params(request, _socket) do
    with \
      "bank:" <> bank_account_id <- request.topic,

      # Get ATM.id and account number from topic
      {account_number, atm_id} <- get_bank_account_id(bank_account_id),

      # Verify ATM.id parameter
      {:ok, atm_id} <- Server.ID.cast(atm_id),

      # Verify account number parameter
      account_number <- String.to_integer(account_number),
      {:ok, account_number} <- BankAccount.cast(account_number),

      # Validate Account.id
      {:ok, account_id} <- Account.ID.cast(request.unsafe["entity_id"]),

      # Validate password
      {:ok, password} <- validate_input(request.unsafe["password"], :password)
    do
        params = %{
          atm_id: atm_id,
          account_number: account_number,
          password: password,
          account_id: account_id
        }

      update_params(request, params, reply: true)
    else
      _ ->
        bad_request(request)
    end
  end

  def check_permissions(request, _socket) do
    atm_id = request.params.atm_id
    account_number = request.params.account_number
    account_id = request.params.account_id
    password = request.params.password
    entity_id = EntityQuery.get_entity_id(account_id)

    with \
    {true, _} <-
      BankHenforcer.can_join?(atm_id, account_number, password, entity_id)
    do
      reply_ok(request)
    else
      {false, reason, _} ->
        reply_error(request, reason)
      _ ->
        bad_request(request)
    end
  end

  @doc """
  Joins a BankAccount.
  """
  def join(request, socket, assign) do
    account_id = request.params.account_id

    atm_id = request.params.atm_id
    account_number = request.params.account_number
    bank_account_id = {atm_id, account_number}

    bootstrap =
      bank_account_id
      |> BankPublic.bootstrap()
      |> BankPublic.render_bootstrap()
      |> WebsocketUtils.wrap_data()

    socket =
      socket
      |> assign.(:atm_id, atm_id)
      |> assign.(:account_number, account_number)
      |> assign.(:account_id, account_id)

    "bank:" <> topic_name = request.topic

    log :join, topic_name,
      relay: request.relay,
      data: %{
        channel: :bank,
        bank_account: topic_name,
        status: :ok
      }

    {:ok, bootstrap, socket}
  end

  docp """
  Gets the atm_id and account_number united by an `@` separate then and return
  as a Tuple
  """
  @spec get_bank_account_id(String.t) ::
    {String.t, String.t}

  defp get_bank_account_id(bank_account_id) do
    bank_account_id
    |> String.split("@")
    |> List.to_tuple
  end

  def log_error(request, _socket, reason) do
    "bank:" <> topic_name = request.topic

    id =
      if Enum.empty?(request.params) do
        nil
      else
        topic_name
      end

    log :join, id,
      relay: request.relay,
      data: %{channel: :bank, status: :error, reason: reason}
  end

end
