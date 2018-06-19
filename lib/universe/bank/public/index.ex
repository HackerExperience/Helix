defmodule Helix.Universe.Bank.Public.Index do

  alias HELL.ClientUtils
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery
  alias Helix.Universe.Bank.Model.BankAccount

  @type index ::
    %{
      balance: BankAccount.balance
    }

  @type rendered_index ::
    %{
      balance: BankAccount.balance,
    }

  @type rendered_transfer ::
    %{
      transfer_id: String.t,
      account_from: String.t,
      account_to: String.t,
      atm_from: String.t,
      atm_to: String.t,
      amount: BankTransfer.amount,
      started_by: String.t,
      started_time: Float.t
    }

  @spec index(ATM.id, BankAccount.account) ::
    index
  @doc """
  Creates index for given BankAccount{atm_id, account_number}.
  """
  def index(atm_id, account_number) do
    bank_account = BankQuery.fetch_account(atm_id, account_number)

    %{
      balance: bank_account.balance,
    }
  end

  @spec render_index(index) ::
    rendered_index
  @doc """
  Renders index to client-friendly format.
  """
  def render_index(index) do
    %{
      balance: index.balance,
    }
  end

  @spec render_transfer(BankTransfer.t) :: rendered_transfer
  @doc """
  Renders a BankTransfer to client-friendly format.
  """
  def render_transfer(transfer) do
    %{
      transfer_id: to_string(transfer.transfer_id),
      account_from: to_string(transfer.account_from),
      account_to: to_string(transfer.account_to),
      atm_from: to_string(transfer.atm_from),
      atm_to: to_string(transfer.atm_to),
      amount: transfer.amount,
      started_by: to_string(transfer.started_by),
      started_time: ClientUtils.to_timestamp(transfer.started_time)
    }
  end
end
