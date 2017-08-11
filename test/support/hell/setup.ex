defmodule HELL.TestHelper.Setup do

  alias Helix.Account.Action.Flow.Account, as: AccountFlow
  alias Helix.Account.Model.Account
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankTransfer
  alias Helix.Universe.NPC.Internal.NPC, as: NPCInternal
  alias Helix.Universe.NPC.Model.NPC

  alias HELL.TestHelper.Random
  alias Helix.Account.Factory, as: AccountFactory
  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Universe.NPC.Helper, as: NPCHelper

  def server do
    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

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

    owner_id = Keyword.get(opts, :owner_id, Account.ID.generate)
    balance = Keyword.get(opts, :balance, 0)

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
    amount = Keyword.get(opts, :amount, 100)
    balance1 = Keyword.get(opts, :balance1, amount)
    balance2 = Keyword.get(opts, :balance2, 0)

    acc1 = bank_account([balance: balance1])
    acc2 = bank_account([balance: balance2])
    started_by = Account.ID.generate()

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
      owner_id: Account.ID.generate()
    }
  end

  def fake_bank_transfer do
    amount = Random.number(min: 1, max: 5000)
    acc1 = bank_account([balance: amount])
    acc2 = fake_bank_account()
    started_by = Account.ID.generate()

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
