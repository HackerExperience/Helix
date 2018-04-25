defmodule Helix.Test.Universe.Bank.Public.BankTest do

  use Helix.Test.Case.Integration

  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.Bank.Public.Bank, as: BankPublic
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  alias Helix.Test.Account.Setup, as: AccountSetup
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Universe.Bank.Helper, as: BankHelper
  alias Helix.Test.Universe.NPC.Helper, as: NPCHelper

  @relay nil

  describe "bootstrap/2" do
    test "bootstrap is created" do
      # Setups a BankAccount.
      bank_account = BankSetup.account!(balance: BankHelper.amount)
      atm_id = bank_account.atm_id
      account_number = bank_account.account_number
      account_id = {atm_id, account_number}

      # Gets Bootstrap.
      bootstrap = BankPublic.bootstrap(account_id)

      # Asserts that the bootstrap's balance is equals to BankAccount's balance.
      assert bootstrap.balance == bank_account.balance
    end
  end

  describe "render_bootstrap/1" do
    test "bootstrap is being properly rendered" do
      # Setups a BankAccount.
      bank_account = BankSetup.account!(balance: BankHelper.amount)
      atm_id = bank_account.atm_id
      account_number = bank_account.account_number
      account_id = {atm_id, account_number}

      # Gets Bootstrap.
      bootstrap = BankPublic.bootstrap(account_id)

      # Renders Bootstrap.
      rendered_bootstrap = BankPublic.render_bootstrap(bootstrap)

      # Asserts that Bootstrap information is correct.
      assert rendered_bootstrap.balance == bank_account.balance
    end
  end

  describe "change_password/4" do
    test "create the process" do
      # Setups a BankAccount.
      bank_account = BankSetup.account!()

      # Stores the password for comparing later.
      old_password = bank_account.password

      # Setups a gateway.
      {gateway, _} = ServerSetup.server()

      # Fetchs ATM server.
      atm = ServerQuery.fetch(bank_account.atm_id)

      # Asserts that process has been created.
      assert {:ok, process} =
        BankPublic.change_password(bank_account, gateway, atm, @relay)

      # Asserts that process properties are correct.
      assert process.gateway_id == gateway.server_id
      assert process.target_id == atm.server_id
      assert process.type == :bank_change_password
      assert process.src_atm_id == bank_account.atm_id
      assert process.src_acc_number == bank_account.account_number
      refute process.src_file_id
      refute process.tgt_connection_id

      # Gets process' id
      process_id = process.process_id

      # Forces process completion
      TOPHelper.force_completion(process_id)

      # Process no longer exists
      refute ProcessQuery.fetch(process_id)

      bank_account =
        BankQuery.fetch_account(atm.server_id, bank_account.account_number)

      # Refutes if password is equals to old password
      refute bank_account.password == old_password
    end
  end

  describe "transfer/6" do
    test "create the process" do
      # Setups a gateway and gets it's entity.
      {gateway, _} = ServerSetup.server()

      # Setups sending bank account.
      bank_acc_snd = BankSetup.account!(balance: 500)

      # Setups eceiving bank account.
      bank_acc_rec = BankSetup.account!()

      # Connection Related Stuff.
      atm = ServerQuery.fetch(bank_acc_snd.atm_id)

      # Setups a Tunnel.
      tunnel = NetworkSetup.tunnel!(
        gateway_id: gateway.server_id,
        destination_id: atm.server_id
      )

      # Setups an Account.
      account = AccountSetup.account!()

      # Asserts the transfer starts correctly.
      assert {:ok, process} =
        BankPublic.transfer(
          bank_acc_snd,
          bank_acc_rec,
          300,
          account,
          gateway,
          tunnel,
          @relay
        )

      # Asserts that process properties are correct.
      assert process.gateway_id == gateway.server_id
      assert process.target_id == bank_acc_rec.atm_id
      assert process.type == :wire_transfer
      assert process.src_connection_id
      refute process.src_file_id
      refute process.tgt_connection_id

      TOPHelper.top_stop(gateway.server_id)
    end
  end

  describe "reveal_password/5" do
    test "creates the process" do
      # Setups a Gateway.
      {gateway, _} = ServerSetup.server()

      # Setups a BankAccount.
      bank_account = BankSetup.account!()

      # Setups a Token.
      token = BankSetup.token!(acc: bank_account)
      token_id = token.token_id

      # Fetches ATM Server.
      atm = ServerQuery.fetch(bank_account.atm_id)

      # Asserts the reveal password process is being created.
      assert {:ok, process} =
        BankPublic.reveal_password(
          bank_account,
          token_id,
          gateway,
          atm,
          @relay
          )

      # Asserts that process properties are correct.
      assert process.gateway_id == gateway.server_id
      assert process.target_id == atm.server_id
      assert process.type == :bank_reveal_password
      assert process.data.token_id == token.token_id
      assert process.data.atm_id == atm.server_id
      assert process.data.account_number == bank_account.account_number
      refute process.src_file_id
      refute process.tgt_connection_id
    end
  end

  describe "open_account/2" do
    test "creates the account" do
      # Setups an Account.
      account = AccountSetup.account!()
      account_id = account.account_id

      # Gets the Bank Server.
      {bank, _} = NPCHelper.bank
      atm_id = List.first(bank.servers).id

      # Asserts that BankAccount is being created.
      assert {:ok, bank_account} =
        BankPublic.open_account(account_id, atm_id)

      # Asserts that BankAccount's Owner is the created account.
      assert bank_account.owner_id == account_id

      # Assert that BankAccount is on database.
      assert BankQuery.fetch_account(atm_id, bank_account.account_number)
    end
  end

  describe "close_account/1" do
    test "deletes the account" do
      # Setups a BankAccount.
      bank_account = BankSetup.account!()

      # Stores atm_id and account_number for trying fetch after deleting.
      atm_id = bank_account.atm_id
      account_number = bank_account.account_number

      # Asserts the BankAccount is being deleted.
      assert :ok =
        BankPublic.close_account(bank_account)

      # Refutes if BankAccount still exists on database.
      refute BankQuery.fetch_account(atm_id, account_number)
    end
  end
end
