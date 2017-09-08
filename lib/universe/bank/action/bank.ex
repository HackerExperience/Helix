defmodule Helix.Universe.Bank.Action.Bank do

  alias Helix.Account.Model.Account
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankTransfer
  alias Helix.Universe.NPC.Query.NPC, as: NPCQuery

  @spec start_transfer(BankAccount.t, BankAccount.t, pos_integer, Account.idt) ::
    {:ok, BankTransfer.t}
    | {:error, {:funds, :insufficient}}
    | {:error, {:account, :notfound}}
    | {:error, Ecto.Changeset.t}
  @doc """
  Starts a bank transfer.

  In case of success, the transfer is started and the funds, specified by
  `amount`, are withdrawn from the source account.

  May fail if the given bank accounts are invalid or if the originating account
  does not have enough funds to perform the transaction.

  This function should not be called directly by Public. Instead,
  `BankTransferFlow.start()` should be use, which will take care of creating
  the transfer process as well.
  """
  defdelegate start_transfer(from_account, to_account, amount, started_by),
    to: BankTransferInternal,
    as: :start

  @spec complete_transfer(BankTransfer.t) ::
    :ok
    | {:error, {:transfer, :notfound}}
    | {:error, :internal}
  @doc """
  Completes the transfer.

  In case of success, the transfer is removed from the database and the amount
  is transferred to the destination account.

  May fail if the given transfer is not found, or if an internal error happened
  during the transaction.

  This function should not be called directly by Public. Instead, it must be
  triggered by the BankTransferCompletedEvent.
  """
  defdelegate complete_transfer(transfer),
    to: BankTransferInternal,
    as: :complete

  @spec abort_transfer(BankTransfer.t) ::
    :ok
    | {:error, {:transfer, :notfound}}
    | {:error, :internal}
  @doc """
  Aborts the transfer.

  In case of success, the transfer is removed from the database and the amount
  is transferred back to the source account.

  May fail if the given transfer is not found, or if an internal error happened
  during the transaction.

  This function should not be called directly by Public. Instead, it must be
  triggered by the BankTransferAbortedEvent.
  """
  defdelegate abort_transfer(transfer),
    to: BankTransferInternal,
    as: :abort

  @spec open_account(Account.idt, ATM.id) ::
    {:ok, BankAccount.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Opens a bank account.
  """
  def open_account(owner, atm) do
    bank =
      atm
      |> EntityQuery.fetch_by_server()
      |> Map.get(:entity_id)
      |> NPCQuery.fetch()

    %{owner_id: owner, atm_id: atm, bank_id: bank}
    |> BankAccountInternal.create()
  end

  @spec close_account(BankAccount.t) ::
    :ok
    | {:error, {:account, :notfound}}
    | {:error, {:account, :notempty}}
  @doc """
  Closes a bank account.

  May fail if the account is invalid or not empty. In order to close an account,
  its balance must be empty.
  """
  defdelegate close_account(account),
    to: BankAccountInternal,
    as: :close
end
