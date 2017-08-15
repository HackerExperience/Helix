defmodule HELL.TestHelper.Setup do

  alias Helix.Account.Action.Flow.Account, as: AccountFlow
  alias Helix.Account.Factory, as: AccountFactory
  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankTransfer
  alias Helix.Universe.NPC.Internal.NPC, as: NPCInternal

  alias HELL.TestHelper.Random
  alias Helix.Universe.NPC.Helper, as: NPCHelper

  def server do
    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    :timer.sleep(100)
    CacheHelper.purge_server(server.server_id)

    {server, account}
  end

  def npc do
    {:ok, npc} = NPCInternal.create(%{npc_type: :download_center})
    npc
  end

  def bank_account(opts \\ []) do
    bank = NPCHelper.bank()
    atm_id = Enum.random(bank.servers).id

    owner_id = Access.get(opts, :owner_id, Random.pk())
    balance = Access.get(opts, :balance, 0)

    params = %{
      bank_id: bank.id,
      atm_id: atm_id,
      owner_id: owner_id
    }

    {:ok, acc} = BankAccountInternal.create(params)

    if balance > 0 do
      {:ok, acc} = BankAccountInternal.deposit(acc, balance)
      acc
    else
      acc
    end
  end

  def bank_transfer(opts \\ []) do
    amount = Access.get(opts, :amount, 100)
    balance1 = Access.get(opts, :balance1, amount)
    balance2 = Access.get(opts, :balance2, 0)

    acc1 = bank_account([balance: balance1])
    acc2 = bank_account([balance: balance2])
    started_by = Random.pk()

    {:ok, transfer} = BankTransferInternal.start(acc1, acc2, amount, started_by)
    transfer
  end

  def fake_bank_account do
    bank = NPCHelper.bank()
    atm_id = Enum.random(bank.servers).id

    %BankAccount{
      account_number: Random.number(min: 100_000, max: 999_999),
      balance: Random.number(min: 0),
      bank_id: bank.id,
      atm_id: atm_id,
      password: "secret",
      owner_id: Random.pk()
    }
  end

  def fake_bank_transfer do
    amount = Random.number(min: 1, max: 5000)
    acc1 = bank_account([balance: amount])
    acc2 = fake_bank_account()
    started_by = Random.pk()

    %BankTransfer{
      transfer_id: BankTransfer.ID.generate(),
      account_from: acc1.account_number,
      account_to: acc2.account_number,
      atm_from: acc1.atm_id,
      atm_to: acc2.atm_id,
      amount: amount,
      started_by: started_by,
      started_time: DateTime.utc_now()
    }
  end
end
