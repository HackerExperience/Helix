defmodule Helix.Universe.Bank.Henforcer.Bank do

  import Helix.Henforcer

  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer
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

  """
  def password_valid?(%BankAccount{password: password}, password),
    do: reply_ok(%{password: password})
  def password_valid?(_, _),
    do: reply_error({:password, :invalid})

  def can_join?(atm_id, account_number, password, entity_id) do
    with \
      {true, r1} <- account_exists?(atm_id, account_number),
      bank_account = r1.bank_account,
      {true, r2} <- password_valid?(bank_account, password),
      {true, r3} <- EntityHenforcer.entity_exists?(entity_id)
    do
      {true, relay([r1, r2, r3])}
    end
  end
end
