defmodule Helix.Universe.Bank.Internal.BankTransfer do

  alias Helix.Account.Model.Account
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankTransfer
  alias Helix.Universe.Repo

  @spec fetch(BankTransfer.idtb) ::
    BankTransfer.t
    | nil
  def fetch(transfer_id),
    do: Repo.get(BankTransfer, transfer_id)

  @spec fetch_for_update(BankTransfer.idtb) ::
    BankTransfer.t
    | nil
  @doc """
  Fetches a bank transfer, locking it for external updates. Must be used within
  a transaction.
  """
  def fetch_for_update(transfer_id) do
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
    trans =
      Repo.transaction(fn ->
        Repo.serializable_transaction()

        with {:ok, _} <- BankAccountInternal.withdraw(from_acc, amount) do
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

  @spec complete(BankTransfer.idt) ::
    :ok
    | {:error, {:transfer, :notfound}}
    | {:error, :internal}
  def complete(transfer = %BankTransfer{}),
    do: complete(transfer.transfer_id)
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
          _ ->
            {:error, :internal}
        end
      end)

    case trans do
      {:ok, result} ->
        result
    end
  end

  @spec abort(BankTransfer.idt) ::
    :ok
    | {:error, {:transfer, :notfound}}
    | {:error, :internal}
  def abort(transfer = %BankTransfer{}),
    do: abort(transfer.transfer_id)
  def abort(transfer_id) do
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
          _ ->
            {:error, :internal}
        end
      end)

    case trans do
      {:ok, result} ->
        result
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

  @spec delete(BankTransfer.t) ::
    :ok
  defp delete(transfer) do
    Repo.delete(transfer)

    :ok
  end
end
