defmodule Helix.Universe.Bank.Internal.BankAccount do

  alias Helix.Account.Model.Account
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Repo

  @spec fetch(BankAccount.account) ::
    BankAccount.t
    | nil
  def fetch(account_number),
    do: Repo.get(BankAccount, account_number)

  @spec fetch_for_update(BankAccount.account) ::
    BankAccount.t
    | nil
  @doc """
  Fetches a bank account, locking it for external updates. Must be used within
  a transaction.
  """
  def fetch_for_update(account_number) do
    account_number
    |> BankAccount.Query.by_id()
    |> BankAccount.Query.lock_for_update()
    |> Repo.one()
  end

  @spec get_balance(BankAccount.t | BankAccount.account) ::
    non_neg_integer
  def get_balance(account = %BankAccount{}),
    do: get_balance(account.account_number)
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

  @spec deposit(BankAccount.t | BankAccount.account, pos_integer) ::
    {:ok, BankAccount.t}
    | {:error, {:account, :notfound}}
    | {:error, Ecto.Changeset.t}
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

  @spec withdraw(BankAccount.t | BankAccount.account, pos_integer) ::
    {:ok, BankAccount.t}
    | {:error, {:account, :notfound}}
    | {:error, {:funds, :insufficient}}
    | {:error, Ecto.Changeset.t}
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

  @spec close(BankAccount.t | BankAccount.account) ::
    :ok
    | {:error, {:account, :notfound}}
    | {:error, {:account, :notempty}}
  def close(account = %BankAccount{}),
    do: close(account.account_number)
  def close(account_number) do
    trans =
      Repo.transaction(fn ->
        Repo.serializable_transaction()

        with \
          account = fetch_for_update(account_number),
          true <- not is_nil(account) || :nxaccount,
          true <- account.balance == 0 || :notempty
        do
          delete(account)
        else
          :nxaccount ->
            {:error, {:account, :notfound}}
          :notempty ->
            {:error, {:account, :notempty}}
        end
      end)

    case trans do
      {:ok, result} ->
        result
    end
  end

  defp delete(account) do
    Repo.delete(account)

    :ok
  end
end
