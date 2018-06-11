defmodule Helix.Universe.Bank.Henforcer.Bank do

  import Helix.Henforcer

  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Model.Bank
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankToken
  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer
  alias Helix.Network.Henforcer.Network, as: NetworkHenforcer
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  @type account_exists_relay :: %{bank_account: BankAccount.t}
  @type account_exists_relay_partial :: %{}
  @type account_exists_error ::
    {false, {:bank_account, :not_found}, account_exists_relay_partial}

  @spec account_exists?(ATM.idt, BankAccount.account) ::
    {true, account_exists_relay}
    | account_exists_error
  @doc """
  Henforces that the given bank account ({atm_id, account_number}) exists.
  """
  def account_exists?(atm_id = %Server.ID{}, account_number) do
    case BankQuery.fetch_account(atm_id, account_number) do
      bank_acc = %BankAccount{} ->
        reply_ok(%{bank_account: bank_acc})
      _ ->
        reply_error({:bank_account, :not_found})
    end
  end


  @type password_valid_relay :: %{}
  @type password_valid_relay_partial :: %{}
  @type password_valid_error ::
    {false, {:password, :invalid}, password_valid_relay_partial}

  @spec password_valid?(BankAccount.t, BankAccount.password) ::
    {true, password_valid_relay}
    | password_valid_error
  @doc """
  Henforces that the given password is the same as given account's password
  """
  def password_valid?(%BankAccount{password: password}, password),
    do: reply_ok(%{password: password})
  def password_valid?(_, _),
    do: reply_error({:password, :invalid})

  @type can_join_password_relay :: %{}
  @type can_join_password_error ::
  password_valid_error
  | account_exists_error
  @type can_join_password_partial :: %{}

  @spec can_join_password?(ATM.id, BankAccount.number, String.t, Entity.id) ::
  {true, can_join_password_relay}
  | {false, can_join_password_error, can_join_password_partial}
  @doc """
  Henforces that the player can join with given password
  """
  def can_join_password?(atm_id, account_number, password, entity_id) do
    with \
      {true, r1} <- account_exists?(atm_id, account_number),
      bank_account = r1.bank_account,
      {true, r2} <- password_valid?(bank_account, password),
      {true, r3} <- EntityHenforcer.entity_exists?(entity_id)
    do
      reply_ok(relay([r1, r2, r3]))
    end
  end

  @type can_join_token_relay :: %{}
  @type can_join_token_error ::
  token_exists_error
  | token_valid_error
  | account_exists_error
  @type can_join_token_partial :: %{}

  @spec can_join_token?(ATM.id, BankAccount.number, BankToken.id, Entity.id) ::
  {true, can_join_token_relay}
  | {false, can_join_token_error, can_join_token_partial}
  @doc """
  Henforces that the player can join with the given token
  """
  def can_join_token?(atm_id, account_number, token, entity_id) do
    with \
      {true, r1} <- account_exists?(atm_id, account_number),
      bank_account = r1.bank_account,
      {true, r2} <- token_valid?(bank_account, token),
      {true, r3} <- EntityHenforcer.entity_exists?(entity_id)
    do
      reply_ok(relay([r1, r2, r3]))
    end
  end

  @type token_valid_relay :: %{token: BankToken.t}
  @type token_valid_relay_partial :: %{}
  @type invalid_error ::
    {false, {:token, :not_belongs}, token_valid_relay_partial}
  @type token_valid_error ::
    invalid_error
    | token_exists_error
    | token_not_expired_error

  @spec token_valid?(BankAccount.t, BankToken.id) ::
  {true, token_valid_relay}
  | token_valid_error
  @doc """
  Henforces that given token exists, is not expired and matches the bank account
  data
  """
  def token_valid?(bank_account, token) do
    with \
      {true, r1} <- token_exists?(token),
      token = r1.token,
      true <- token.atm_id == bank_account.atm_id,
      true <- token.account_number == bank_account.account_number,
      {true, r2} <- token_not_expired?(token)
    do
      reply_ok(r2)
    else
      {false, reason, _} ->
        reply_error(reason)
      false ->
        reply_error({:token, :not_belongs})
    end
  end

  @type token_exists_relay :: %{}
  @type token_exists_error ::
    {false, {:token, :not_found}, token_exists_relay_partial}
  @type token_exists_relay_partial :: %{}

  @spec token_exists?(BankToken.id) ::
  {true, token_exists_relay}
  | token_exists_error
  @doc """
  Henforces that given token exists on the database
  """
  def token_exists?(nil),
    do: reply_error{:token, :not_found}
  def token_exists?(token) do
    case BankQuery.fetch_token(token) do
      token = %BankToken{} ->
        reply_ok(%{token: token})
      _ ->
        reply_error({:token, :not_found})
    end
  end

  @type token_not_expired_relay :: %{}
  @type token_not_expired_error ::
    {false, {:token, :expired}, token_not_expired_partial_relay}
  @type token_not_expired_partial_relay :: %{}

  @spec token_exists?(BankToken.t) ::
  {true, token_not_expired_relay}
  | token_not_expired_error
  @doc """
  Henforces that the given token is not expired
  """
  def token_not_expired?(token) do
    time_now =
      DateTime.utc_now()

    token_exp =
      token.expiration_date

    case DateTime.compare(time_now, token_exp) do
      :gt ->
        reply_error{:token, :expired}
      _ ->
        reply_ok(%{token: token})
    end
  end

  @type transfer_error ::
    account_exists_error
    | transfer_no_funds_error

  @type can_transfer_relay ::
    %{
      amount: BankAccount.amount,
      to_account: BankAccount.t
    }
  @type transfer_no_funds_error ::
    {:bank_account, :no_funds}
  @spec can_transfer?(
    {Network.ID, Network.ip},
    BankAccount.account,
    {ATM.idt, BankAccount.account},
    non_neg_integer
    ) ::
    {true, can_transfer_relay}
    | {false, transfer_error, %{}}
  @doc """
  Henforces that given account can transfer to another given account
  """
  def can_transfer?({net_id, ip}, to_acc_num, {atm_id, acc_num}, amount)
    do
      with \
        {true, r1} <- NetworkHenforcer.nip_exists?(net_id, ip),
        {true, r2} <- is_a_bank?(r1.server.server_id),
        to_atm_id = r2.atm.atm_id,
        {true, r3} <- account_exists?(to_atm_id, to_acc_num),
        {_r3, to_account} <- get_and_drop(r3, :bank_account),
        {true, r4} <- account_exists?(atm_id, acc_num),
        {true, r5} <- has_enough_funds?(r4.bank_account, amount)
      do
        relay =
          %{
            to_account: to_account
          }
        reply_ok(relay([relay, r5]))
      end
  end

  @type has_enough_funds_relay :: %{amount: BankAccount.amount}
  @type has_enough_funds_partial_relay :: %{}

  @spec has_enough_funds?(BankAccount.t, BankAccount.amount) ::
  {true, has_enough_funds_relay}
  | {false, transfer_no_funds_error, has_enough_funds_partial_relay}
  @doc """
  Henforces that given account has given amount in the balance
  """
  def has_enough_funds?(account, amount) do
      if account.balance >= amount do
        reply_ok()
      else
        reply_error({:bank_account, :no_funds})
      end
      |> wrap_relay(%{amount: amount})
  end

  @type owns_account_relay :: %{bank_account: BankAccount.t}
  @type owns_account_partial_relay :: %{}
  @type owns_account_error ::
    {false, {:bank_account, :not_belongs}, owns_account_partial_relay}
  def owns_account?(entity = %Entity{}, account = %BankAccount{}) do
    with \
      entity_id = to_string(entity.entity_id),
      true <- account.owner_id == Account.ID.cast!(entity_id)
    do
      reply_ok(%{bank_account: account})
    else
      _ ->
        reply_error({:bank_account, :not_belongs})
    end
  end

  @type is_empty_relay :: %{bank_account: BankAccount.t}
  @type is_empty_partial_relay :: %{}
  @type is_empty_error ::
    {false, {:bank_account, :not_empty}, is_empty_partial_relay}

  @spec is_empty?(BankAccount.t) ::
  {true, is_empty_relay}
  | is_empty_error
  @doc """
  Henforces that the given account is empty.
  """
  def is_empty?(account = %BankAccount{}) do
    if account.balance == 0 do
      reply_ok()
    else
      reply_error({:bank_account, :not_empty})
    end
    |> wrap_relay(%{bank_account: account})
  end

  @type can_close_relay :: %{}
  @type can_close_partial_relay :: %{}
  @type can_close_error ::
  account_exists_error
  | is_empty_error

  @spec can_close?(Server.id, BankAccount.account) ::
  {true, can_close_relay}
  | can_close_error
  @doc """
  Henforces that player can close account
  """
  def can_close?(atm_id = %Server.ID{}, account_number) do
    with \
      {true, r1} <- account_exists?(atm_id, account_number),
      {true, _r2} <- is_empty?(r1.bank_account)
    do
      reply_ok()
    end
  end

  @type is_a_bank_relay :: %{}
  @type is_a_bank_partial_relay :: %{}
  @type is_a_bank_error :: {false, {:atm, :not_a_bank}, %{}}

  @spec is_a_bank?(Server.id) ::
  is_a_bank_relay
  | is_a_bank_error
  @doc """
  Henforces that given server is a bank
  """
  def is_a_bank?(server_id = %Server.ID{}) do
    case BankQuery.fetch_atm(server_id) do
      atm = %ATM{} ->
        reply_ok(%{atm: atm})
      _ ->
        reply_error({:atm, :not_a_bank})
    end
  end

  @type can_create_account_relay ::
    %{
      bank_id: Bank.id,
      atm_id: ATM.id
    }
  @type can_create_account_partial_relay :: %{}
  @type can_create_account_error ::
  is_a_bank_error

  @spec can_create_account?(Server.t) ::
  {true, can_create_account_relay}
  | can_create_account_error
  @doc """
  Henforces that player can create a account
  """
  def can_create_account?(atm = %Server{}) do
    with \
      {true, r1} <- is_a_bank?(atm.server_id),
      bank_id = r1.atm.bank_id,
      atm_id = r1.atm.atm_id
    do
      relay =
        %{
          bank_id: bank_id,
          atm_id: atm_id
        }

      reply_ok(relay)
    else
      {false, reason, _} ->
        reply_error(reason)
    end
  end
end
