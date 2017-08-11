defmodule Helix.Universe.Bank.Internal.BankTransfer do

  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankTransfer
  alias Helix.Universe.Repo

  def fetch(transfer_id),
    do: Repo.get(BankTransfer, transfer_id)

  def fetch_for_update(transfer_id) do
    transfer_id
    |> BankTransfer.Query.by_id()
    |> BankTransfer.Query.lock_for_update()
    |> Repo.one()
  end

  def start(from_acc, to_acc, amount, started_by) do
    trans =
      Repo.transaction(fn ->
        Repo.serializable_transaction()

        with {:ok, acc} <- BankAccountInternal.withdraw(from_acc, amount) do
          %{
            account_from: from_acc.account_number,
            account_to: to_acc.account_number,
            atm_from: from_acc.atm_id,
            atm_to: to_acc.atm_id,
            amount: amount,
            started_by: started_by
          }
          |> create()
        end
      end)

    case trans do
      {:ok, result} ->
        result
    end
  end

  def complete(transfer_id) do
    deposit_money = fn(account_to, amount) ->
      BankAccountInternal.deposit(account_to, amount)
    end

    trans =
      Repo.transaction(fn ->
        Repo.serializable_transaction()

        with \
          transfer = %{} <- fetch_for_update(transfer_id) || :nxtransfer,
          # Transfer money to recipient
          {:ok, _} <- deposit_money.(transfer.account_to, transfer.amount)
        do
          # Remove transfer entry
          delete(transfer)
        else
          :nxtransfer ->
            {:error, {:transfer, :notfound}}
          error ->
            error
        end
      end)

    case trans do
      {:ok, result} ->
        result
    end
  end

  defp create(params) do
    params
    |> BankTransfer.create_changeset()
    |> Repo.insert()
  end

  def cancel(transfer_id) do
    refund_money = fn(account_from, amount) ->
      BankAccountInternal.deposit(account_from, amount)
    end

    trans =
      Repo.transaction(fn ->
        Repo.serializable_transaction()

        with \
          transfer = %{} <- fetch_for_update(transfer_id) || :nxtransfer,
          # Refund transfer money
          {:ok, _} <- refund_money.(transfer.account_from, transfer.amount)
        do
          # Remove transfer entry
          delete(transfer)
        else
          :nxtransfer ->
            {:error, {:transfer, :notfound}}
          error ->
            error
        end

        # TODO: Remove process too (or vice versa)
      end)

    case trans do
      {:ok, result} ->
        result
    end
  end

  defp delete(transfer) do
    Repo.delete(transfer)

    :ok
  end
end

