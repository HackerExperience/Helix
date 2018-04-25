import Helix.Websocket.Join

join Helix.Universe.Bank.Websocket.Channel.Bank.Join do
  @moduledoc """
  Joinable implementation for the Bank channel.

  There are two main methods to joining the Bank channel:
    - using password
    - using token

  On Logging with password the player has access for unlimited time on the
  BankAccount that he logged in.

  On Logging with token the player has access for the time that the token is not
  expired, when logged with a token the player can convert the token to the
  password.

  Params:
   - password: Password for given account.
   - token: Token for the given account.
   - *entity_id: Entity.id for the logging player.
   - *gateway_id: Server.id for the logging server.
   - bounce_id: Bounce id, if is nil logs with no bounce.

  The given password or token must match the given BankAccount, otherwise the
  user is denied access to the BankAccount.

  It Returns Bootstrap for the logged BankAccount.
  """

  use Helix.Logger

  import HELL.Macros

  alias Helix.Websocket.Utils, as: WebsocketUtils
  alias Helix.Account.Model.Account
  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Model.Server
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Network.Henforcer.Bounce, as: BounceHenforcer
  alias Helix.Universe.Bank.Action.Flow.BankAccount, as: BankAccountFlow
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Henforcer.Bank, as: BankHenforcer
  alias Helix.Universe.Bank.Public.Bank, as: BankPublic

  def check_params(request, _socket) do
    {_, password} =
      if request.unsafe["password"] do
        validate_input(request.unsafe["password"], :password)
      else
       {:ok, nil}
      end

    {_, token} =
      if request.unsafe["token"] do
        validate_input(request.unsafe["token"], :token)
      else
        {:ok, nil}
      end
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

      # Validate Gateway.id
      {:ok, gateway_id} <- Server.ID.cast(request.unsafe["gateway_id"]),

      # Validate Bounce.id
      {:ok, bounce_id} <- validate_bounce(request.unsafe["bounce_id"]),

      # Check if has password or token
      true <- not is_nil(password) or not is_nil(token)
    do
      params = %{
          atm_id: atm_id,
          account_number: account_number,
          account_id: account_id,
          gateway_id: gateway_id,
          bounce_id: bounce_id
      }

      params =
       cond do
        password != nil ->
          Map.put(params, :password, password)
        token != nil ->
          Map.put(params, :token, token)
        true ->
          params
       end

      update_params(request, params, reply: true)
    else
      _ ->
        bad_request(request)
    end
  end

  def check_permissions(request = %{params: %{token: token}}, _socket) do
    atm_id = request.params.atm_id
    account_number = request.params.account_number
    account_id = request.params.account_id
    password = request.params.password
    entity_id = EntityQuery.get_entity_id(account_id)
    gateway_id = request.params.gateway_id
    bounce_id = request.params.bounce_id

    with \
    {true, r1} <-
      BankHenforcer.can_join_token?(atm_id, account_number, token, entity_id),
    bank_account = r1.bank_account,
    entity_id = r1.entity.entity_id,
    token = r1.token,

    # Checking if gateway exists
    {true, r2} <- ServerHenforcer.server_exists?(gateway_id),
    gateway = r2.server,

    # Checking if gateway belongs to entity
    {true, r3} <- EntityHenforcer.owns_server?(entity_id, gateway),
    gateway = r3.server,

    # Checking if bounce exists
    {true, r4} <- BounceHenforcer.can_use_bounce?(entity_id, bounce_id),
    bounce = r4.bounce
    do
      meta =
        %{
          gateway: gateway,
          account_id: account_id,
          entity_id: entity_id,
          bank_account: bank_account,
          token: token,
          bounce: bounce
        }
      update_meta(request, meta, reply: true)
    else
      {false, reason, _} ->
        reply_error(request, reason)
      _ ->
        bad_request(request)
    end
  end

  def check_permissions(request = %{params: %{password: password}}, _socket) do
    atm_id = request.params.atm_id
    account_number = request.params.account_number
    account_id = request.params.account_id
    entity_id = EntityQuery.get_entity_id(account_id)
    gateway_id = request.params.gateway_id
    bounce_id = request.params.bounce_id

    with \
    {true, r1} <-
      BankHenforcer.can_join_password?(
        atm_id,
        account_number,
        password,
        entity_id
        ),
    bank_account = r1.bank_account,
    password = r1.password,
    entity_id = r1.entity.entity_id,

    # Checking if gateway exists
    {true, r2} <- ServerHenforcer.server_exists?(gateway_id),
    gateway = r2.server,

    # Checking if gateway belongs to entity
    {true, r3} <- EntityHenforcer.owns_server?(entity_id, gateway),
    gateway = r3.server,

    # Checking if bounce exists
    {true, r4} <- BounceHenforcer.can_use_bounce?(entity_id, bounce_id),
    bounce = r4.bounce
    do
      meta =
        %{
          gateway: gateway,
          account_id: account_id,
          entity_id: entity_id,
          bank_account: bank_account,
          password: password,
          bounce: bounce
        }
      update_meta(request, meta, reply: true)
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
  def join(request = %{meta: %{password: password}}, socket, assign) do
    account_id = request.meta.account_id
    gateway = request.meta.gateway
    bounce = request.meta.bounce
    entity_id = request.meta.entity_id
    atm_id = request.meta.bank_account.atm_id
    account_number = request.meta.bank_account.account_number
    bank_account_id = {atm_id, account_number}

    bounce_id =
      if bounce do
        bounce.bounce_id
      else
        nil
      end

    with \
      {:ok, tunnel, connection} <-
        BankAccountFlow.login_password(
          atm_id,
          account_number,
          gateway.server_id,
          bounce_id,
          password
          )
    do
      gateway_data =
        %{
          server_id: gateway.server_id,
          entity_id: entity_id
        }

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
        |> assign.(:gateway, gateway_data)
        |> assign.(:tunnel, tunnel)
        |> assign.(:bank_login, connection)

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
  end

  def join(request = %{meta: %{token: token}}, socket, assign) do
    account_id = request.meta.account_id
    gateway = request.meta.gateway
    bounce = request.meta.bounce
    entity_id = request.meta.entity_id
    atm_id = request.meta.bank_account.atm_id
    account_number = request.meta.bank_account.account_number
    bank_account_id = {atm_id, account_number}

    bounce_id =
      if bounce do
        bounce.bounce_id
      else
        nil
      end

    with \
      {:ok, tunnel, connection} <-
        BankAccountFlow.login_token(
          atm_id,
          account_number,
          gateway.server_id,
          bounce_id,
          token
        )
    do
      gateway_data =
        %{
          server_id: gateway.server_id,
          entity_id: entity_id
        }

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
        |> assign.(:gateway, gateway_data)
        |> assign.(:tunnel, tunnel)
        |> assign.(:bank_login, connection)

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
      data:
        %{
          channel: :bank,
          type: request.type,
          status: :error,
          reason: reason
        }
  end

end
