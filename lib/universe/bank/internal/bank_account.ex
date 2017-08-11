defmodule Helix.Universe.Bank.Internal.BankAccount do

  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Repo

  def fetch(account_number),
    do: Repo.get(BankAccount, account_number)

  def get_balance(account_number) do
    balance =
      account_number
      |> BankAccount.Query.by_id()
      |> BankAccount.Query.select_balance()
      |> Repo.one()

    if balance do
      balance
    else
      0
    end
  end

  def get_accounts(owner_id) do
    owner_id
    |> BankAccount.Query.by_owner()
    |> BankAccount.Query.order_by_creation_date()
    |> Repo.all()
  end

  def get_total_funds(owner_id) do
    owner_id
    |> BankAccount.Query.by_owner()
    |> BankAccount.Query.sum_balance()
    |> Repo.one()
  end

  def create(params) do
    params
    |> BankAccount.create_changeset()
    |> Repo.insert()
  end

  def change_password(account) do
    account
    |> BankAccount.change_password()
    |> Repo.update()
  end

  def delete(account) do
    Repo.delete(account)

    :ok
  end

  def fetch_for_update(account_number) do
    account_number
    |> BankAccount.Query.by_id()
    |> BankAccount.Query.lock_for_update()
    |> Repo.one()
  end

  def deposit(account = %BankAccount{}, amount),
    do: deposit(account.account_number, amount)
  def deposit(account_number, amount) do
    trans =
      Repo.transaction(fn ->
        Repo.serializable_transaction()

        account = fetch_for_update(account_number)

        if not is_nil(account) do
          account
          |> BankAccount.deposit(amount)
          |> Repo.update()
        else
          {:error, {:account, :notfound}}
        end
      end)

    case trans do
      {:ok, result} ->
        result
    end
  end

  def withdraw(account = %BankAccount{}, amount),
    do: withdraw(account.account_number, amount)
  def withdraw(account_number, amount) do
    trans =
      Repo.transaction(fn ->
        Repo.serializable_transaction()

        with \
          account = fetch_for_update(account_number),
          true <- not is_nil(account) || :nxaccount,
          true <- account.balance >= amount || :nxfunds
        do
          account
          |> BankAccount.withdraw(amount)
          |> Repo.update()
        else
          :nxaccount ->
            {:error, {:account, :notfound}}
          :nxfunds ->
            {:error, {:funds, :insufficient}}
        end
      end)

    case trans do
      {:ok, result} ->
        result
    end
  end
end
