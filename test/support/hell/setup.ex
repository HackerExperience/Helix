defmodule HELL.TestHelper.Setup do

  alias Helix.Account.Action.Flow.Account, as: AccountFlow
  alias Helix.Account.Factory, as: AccountFactory
  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal
  alias Helix.Universe.Bank.Internal.BankAccount, as: BankAccountInternal
  alias Helix.Universe.NPC.Internal.NPC, as: NPCInternal
  alias Helix.Universe.NPC.Model.NPC

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

  def bank_transfer do
    acc1 = bank_account([balance: 500])
    acc2 = bank_account()
    amount = 100
    started_by = Random.pk()

    {:ok, transfer} = BankTransferInternal.start(acc1, acc2, amount, started_by)
    transfer
  end

end
