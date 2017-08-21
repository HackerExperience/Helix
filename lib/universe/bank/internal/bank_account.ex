defmodule Helix.Universe.Bank.Internal.BankAccount do

  alias Helix.Account.Model.Account
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Repo

  @spec fetch(ATM.idt, BankAccount.account) ::
    BankAccount.t
    | nil
  def fetch(atm, account_number) do
    atm
    |> BankAccount.Query.by_atm_account(account_number)
    |> Repo.one()
  end

  @spec fetch_for_update(ATM.idt, BankAccount.account) ::
    BankAccount.t
    | nil
    | no_return
  @doc """
  Fetches a bank account, locking it for external updates. Must be used within
  a transaction.
  """
  def fetch_for_update(atm, account_number) do
    unless Repo.in_transaction?() do
      raise "Transaction required in order to acquiring lock"
    end

    atm
    |> BankAccount.Query.by_atm_account(account_number)
    |> BankAccount.Query.lock_for_update()
    |> Repo.one()
  end

  @spec get_balance(BankAccount.t) ::
    non_neg_integer
  def get_balance(account) do
    balance =
      account.atm_id
      |> BankAccount.Query.by_atm_account(account.account_number)
      |> BankAccount.Query.select_balance()
      |> Repo.one()

    if balance do
      balance
    else
      0
    end
  end

  @spec get_accounts(Account.id) ::
    [BankAccount.t]
  def get_accounts(owner_id) do
    owner_id
    |> BankAccount.Query.by_owner()
    |> BankAccount.Query.order_by_creation_date()
    |> Repo.all()
  end

  @spec get_total_funds(Account.id) ::
    non_neg_integer
  def get_total_funds(owner_id) do
    total =
      owner_id
      |> BankAccount.Query.by_owner()
      |> BankAccount.Query.select_sum_balance()
      |> Repo.one()

    if total do
      total
    else
      0
    end
  end

  @spec create(BankAccount.creation_params) ::
    {:ok, BankAccount.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> BankAccount.create_changeset()
    |> Repo.insert()
  end

  @spec change_password(BankAccount.t) ::
    {:ok, BankAccount.t}
    | {:error, Ecto.Changeset.t}
  def change_password(account) do
    account
    |> BankAccount.change_password()
    |> Repo.update()
  end

  @spec deposit(BankAccount.t, pos_integer) ::
    {:ok, BankAccount.t}
    | {:error, {:account, :notfound}}
    | {:error, Ecto.Changeset.t}
  def deposit(account, amount) do
    Repo.transaction(fn ->
      Repo.serializable_transaction()

      account = fetch_for_update(account.atm_id, account.account_number)

      if not is_nil(account) do
        account
        |> BankAccount.deposit(amount)
        |> Repo.update!()
      else
        Repo.rollback({:account, :notfound})
      end
    end)
  end

  @spec withdraw(BankAccount.t, pos_integer) ::
    {:ok, BankAccount.t}
    | {:error, {:account, :notfound}}
    | {:error, {:funds, :insufficient}}
    | {:error, Ecto.Changeset.t}
  def withdraw(account, amount) do
    Repo.transaction(fn ->
      Repo.serializable_transaction()

      account = fetch_for_update(account.atm_id, account.account_number)

      with \
        true <- not is_nil(account) || {:account, :notfound},
        true <- account.balance >= amount || {:funds, :insufficient}
      do
        account
        |> BankAccount.withdraw(amount)
        |> Repo.update!()
      else
        error = {_, _} ->
          Repo.rollback(error)
      end
    end)
  end

  @spec close(BankAccount.t) ::
    :ok
    | {:error, {:account, :notfound}}
    | {:error, {:account, :notempty}}
  def close(account) do
    trans =
      Repo.transaction(fn ->
        Repo.serializable_transaction()

        account = fetch_for_update(account.atm_id, account.account_number)

        with \
          true <- not is_nil(account) || {:account, :notfound},
          true <- account.balance == 0 || {:account, :notempty}
        do
          delete(account)
        else
          error = {_, _} ->
            Repo.rollback(error)
        end
      end)

    case trans do
      {:ok, result} ->
        result
      error ->
        error
    end
  end

  @spec delete(BankAccount.t) ::
    :ok
  defp delete(account) do
    Repo.delete(account)

    :ok
  end
end
