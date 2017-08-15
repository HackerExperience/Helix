defmodule Helix.Universe.Bank.Internal.BankTransfer do

  alias Helix.Account.Model.Account
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankTransfer
  alias Helix.Universe.Repo

  @spec fetch(BankTransfer.id) ::
    BankTransfer.t
    | nil
  def fetch(transfer_id),
    do: Repo.get(BankTransfer, transfer_id)

  @spec fetch_for_update(BankTransfer.id) ::
    BankTransfer.t
    | nil
    | no_return
  @doc """
  Fetches a bank transfer, locking it for external updates. Must be used within
  a transaction.
  """
  def fetch_for_update(transfer_id) do
    unless Repo.in_transaction?() do
      raise "Transaction required in order to acquire lock"
    end

    transfer_id
    |> BankTransfer.Query.by_id()
    |> BankTransfer.Query.lock_for_update()
    |> Repo.one()
  end

  @spec start(BankAccount.t, BankAccount.t, pos_integer, Account.idt) ::
    {:ok, BankTransfer.t}
    | {:error, {:funds, :insufficient}}
    | {:error, {:account, :notfound}}
    | {:error, Ecto.Changeset.t}
  def start(from_acc, to_acc, amount, started_by) do
    Repo.transaction(fn ->
      Repo.serializable_transaction()

      case BankAccountInternal.withdraw(from_acc, amount) do
        {:ok, _} ->
          params = %{
            account_from: from_acc.account_number,
            account_to: to_acc.account_number,
            atm_from: from_acc.atm_id,
            atm_to: to_acc.atm_id,
            amount: amount,
            started_by: started_by
          }
          create!(params)
        {:error, e} ->
          Repo.rollback(e)
      end
    end)
  end

  @spec complete(BankTransfer.t) ::
    :ok
    | {:error, {:transfer, :notfound}}
    | {:error, :internal}
  def complete(transfer) do
    deposit_money = fn(transfer) ->
      account_to = BankAccountInternal.fetch_for_update(
        transfer.atm_to,
        transfer.account_to)

      BankAccountInternal.deposit(account_to, transfer.amount)
    end

    trans =
      Repo.transaction(fn ->
        Repo.serializable_transaction()

        transfer = fetch_for_update(transfer.transfer_id)

        with \
          true <- not is_nil(transfer) || :nxtransfer,
          # Transfer money to recipient
          {:ok, _} <- deposit_money.(transfer)
        do
          # Remove transfer entry
          delete(transfer)
        else
          :nxtransfer ->
            Repo.rollback({:transfer, :notfound})
          _ ->
            Repo.rollback(:internal)
        end
      end)

    case trans do
      {:ok, result} ->
        result
      error ->
        error
    end
  end

  @spec abort(BankTransfer.t) ::
    :ok
    | {:error, {:transfer, :notfound}}
    | {:error, :internal}
  def abort(transfer) do
      refund_money = fn(transfer) ->
        account_from = BankAccountInternal.fetch_for_update(
          transfer.atm_from,
          transfer.account_from)

        BankAccountInternal.deposit(account_from, transfer.amount)
    end

    trans =
      Repo.transaction(fn ->
        Repo.serializable_transaction()

        transfer = fetch_for_update(transfer.transfer_id)

        with \
          true <- not is_nil(transfer) || :nxtransfer,
          # Refund transfer money
          {:ok, _} <- refund_money.(transfer)
        do
          # Remove transfer entry
          delete(transfer)
        else
          :nxtransfer ->
            Repo.rollback({:transfer, :notfound})
          _ ->
            Repo.rollback(:internal)
        end
      end)

    case trans do
      {:ok, result} ->
        result
      error ->
        error
    end
  end

  @spec create(BankTransfer.creation_params) ::
    {:ok, BankTransfer.t}
    | {:error, Ecto.Changeset.t}
  defp create(params) do
    params
    |> BankTransfer.create_changeset()
    |> Repo.insert()
  end

  @spec create!(BankTransfer.creation_params) ::
    BankTransfer.t
    | no_return
  defp create!(params) do
    {:ok, acc} = create(params)
    acc
  end

  @spec delete(BankTransfer.t) ::
    :ok
  defp delete(transfer) do
    Repo.delete(transfer)

    :ok
  end
end
