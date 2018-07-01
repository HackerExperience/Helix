defmodule Helix.Entity.Internal.DatabaseTest do

  use Helix.Test.Case.Integration

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Entity.Internal.Database, as: DatabaseInternal

  alias HELL.TestHelper.Random
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Entity.Database.Setup, as: DatabaseSetup

  describe "fetch_server/3" do
    test "returns the entry when input exists" do
      {entry, _} = DatabaseSetup.entry_server()

      assert entry ==
        DatabaseInternal.fetch_server(
          entry.entity_id, entry.network_id, entry.server_ip
        )
    end

    test "returns the entry when input exists (with linked viruses)" do
      {entry, _} = DatabaseSetup.entry_server()

      # Link a couple viruses to `entry`
      {v1, _} = DatabaseSetup.entry_virus(from_entry: entry)
      {v2, _} = DatabaseSetup.entry_virus(from_entry: entry)

      db_entry =
        DatabaseInternal.fetch_server(
          entry.entity_id, entry.network_id, entry.server_ip
        )

      # Returned the usual Database.Server entry
      assert db_entry.entity_id == entry.entity_id
      assert db_entry.server_id == entry.server_id

      # With the linked viruses
      assert Enum.sort(db_entry.viruses) == Enum.sort([v1, v2])
    end

    test "returns empty when input isn't found" do
      entity_id = EntityHelper.id()
      server_ip = Random.ipv4()
      network_id = NetworkHelper.internet_id()

      refute DatabaseInternal.fetch_server(entity_id, network_id, server_ip)
    end
  end

  describe "fetch_bank_account/2" do
    test "returns the entry when input exist" do
      {entry, %{acc: acc}} = DatabaseSetup.entry_bank_account()

      assert DatabaseInternal.fetch_bank_account(entry.entity_id, acc)
    end

    test "returns empty when input isn't found" do
      entity_id = EntityHelper.id()
      {acc, _} = BankSetup.account()

      refute DatabaseInternal.fetch_bank_account(entity_id, acc)
    end
  end

  describe "get_database/1" do
    test "empty database" do
      {entity, _} = EntitySetup.entity()

      database = DatabaseInternal.get_database(entity)

      expected =
        %{
          servers: [],
          bank_accounts: []
        }

      assert database == expected
    end

    test "one entry on each section" do
      {entity, _} = EntitySetup.entity()
      entity_id = entity.entity_id

      {entry_server, _} =
        DatabaseSetup.entry_server([entity_id: entity_id])
      {entry_account, _} =
        DatabaseSetup.entry_bank_account([entity_id: entity_id])

      database = DatabaseInternal.get_database(entity_id)

      expected =
        %{
          servers: [entry_server],
          bank_accounts: [entry_account]
        }

      assert database == expected
    end

    test "multiple entries on each section (ordered)" do
      {entity, _} = EntitySetup.entity()
      entity_id = entity.entity_id

      {server1, _} = DatabaseSetup.entry_server([entity_id: entity_id])
      {server2, _} = DatabaseSetup.entry_server([entity_id: entity_id])
      {server3, _} = DatabaseSetup.entry_server([entity_id: entity_id])
      {account1, _} = DatabaseSetup.entry_bank_account([entity_id: entity_id])
      {account2, _} = DatabaseSetup.entry_bank_account([entity_id: entity_id])
      {account3, _} = DatabaseSetup.entry_bank_account([entity_id: entity_id])

      database = DatabaseInternal.get_database(entity_id)

      expected =
        %{
          servers: [server3, server2, server1],
          bank_accounts: [account3, account2, account1]
        }

      assert database == expected
    end
  end

  describe "add_server/5" do
    test "given a valid input, entry is created" do
      {server, %{entity: entity}} = ServerSetup.server()

      {:ok, [nip]} = CacheQuery.from_server_get_nips(server.server_id)

      assert {:ok, entry} =
        DatabaseInternal.add_server(
          entity,
          nip.network_id,
          nip.ip,
          server,
          :vpc)

      assert entry.entity_id == entity.entity_id
      assert entry.server_id == server.server_id
      assert entry.network_id == nip.network_id
      assert entry.server_ip == nip.ip
      assert entry.last_update
      refute entry.password
      refute entry.notes
      refute entry.alias
    end

  end

  describe "add_bank_account/3" do
    test "given a valid input, entry is created" do
      {entity, _} = EntitySetup.entity()

      {acc, _} = BankSetup.account()

      atm_ip = ServerQuery.get_ip(acc.atm_id, NetworkHelper.internet_id())

      assert {:ok, entry} =
        DatabaseInternal.add_bank_account(entity, acc, atm_ip)

      assert entry.entity_id == entity.entity_id
      assert entry.atm_id == acc.atm_id
      assert entry.account_number == acc.account_number
      assert entry.last_update
      refute entry.last_login_date
      refute entry.known_balance
      refute entry.notes
    end
  end

  describe "add_virus/3" do
    test "given a valid input, entry is created" do
      {entry_server, _} = DatabaseSetup.entry_server()
      virus_id = SoftwareHelper.id()

      assert {:ok, entry_virus} =
        DatabaseInternal.add_virus(
          entry_server.entity_id, entry_server.server_id, virus_id
        )

      assert entry_virus.entity_id == entry_server.entity_id
      assert entry_virus.server_id == entry_server.server_id
      assert entry_virus.file_id == virus_id
    end
  end

  describe "update_server_password/2" do
    test "the password is updated" do
      {entry, _} = DatabaseSetup.entry_server()
      password = "rivotril"

      assert {:ok, new_entry} =
        DatabaseInternal.update_server_password(entry, password)
      assert new_entry.password == password

      entry_on_db =
        DatabaseInternal.fetch_server(entry.entity_id,
          entry.network_id,
          entry.server_ip)
      assert entry_on_db.password == password
    end
  end

  describe "update_bank_password/2" do
    test "the password is updated" do
      {entry, %{acc: acc}} = DatabaseSetup.entry_bank_account()
      password = "modafinil"

      assert {:ok, new_entry} =
        DatabaseInternal.update_bank_password(entry, password)
      assert new_entry.password == password

      entry_on_db = DatabaseInternal.fetch_bank_account(entry.entity_id, acc)
      assert entry_on_db.password == password
    end
  end

  describe "update_bank_token/2" do
    test "the password is updated" do
      {entry, %{acc: acc}} = DatabaseSetup.entry_bank_account()
      token = Ecto.UUID.generate()

      assert {:ok, new_entry} =
        DatabaseInternal.update_bank_token(entry, token)
      assert new_entry.token == token

      entry_on_db = DatabaseInternal.fetch_bank_account(entry.entity_id, acc)
      assert entry_on_db.token == token
    end
  end

  describe "update_bank_login/2" do
    test "all related information is updated (login=password)" do
      {entry, %{acc: acc}} = DatabaseSetup.entry_bank_account()

      assert {:ok, new_entry} =
        DatabaseInternal.update_bank_login(entry, acc, nil)

      assert new_entry.password == acc.password
      assert new_entry.known_balance == acc.balance
      assert new_entry.last_login_date

      entry_on_db = DatabaseInternal.fetch_bank_account(entry.entity_id, acc)
      assert entry_on_db == new_entry
    end

    test "all related information is updated (login=token)" do
      {entry, %{acc: acc}} = DatabaseSetup.entry_bank_account()
      token_id = Ecto.UUID.generate()

      assert {:ok, new_entry} =
        DatabaseInternal.update_bank_login(entry, acc, token_id)

      assert new_entry.token == token_id
      refute new_entry.password
      assert new_entry.known_balance == acc.balance
      assert new_entry.last_login_date

      entry_on_db = DatabaseInternal.fetch_bank_account(entry.entity_id, acc)
      assert entry_on_db == new_entry
    end
  end

  describe "delete_server/3" do
    test "entry is removed" do
      {entry, _} = DatabaseSetup.entry_server()

      # Make sure it is on the DB
      assert DatabaseInternal.fetch_server(
        entry.entity_id,
        entry.network_id,
        entry.server_ip)

      # Delete
      assert :ok == DatabaseInternal.delete_server(entry)

      # No longer on the DB
      refute DatabaseInternal.fetch_server(
        entry.entity_id,
        entry.network_id,
        entry.server_ip)
    end
  end

  describe "delete_bank_account/1" do
    test "entry is removed" do
      {entry, %{acc: acc}} = DatabaseSetup.entry_bank_account()

      # Make sure it is on the DB
      assert DatabaseInternal.fetch_bank_account(entry.entity_id, acc)

      # Delete
      assert :ok == DatabaseInternal.delete_bank_account(entry)

      # No longer on the DB
      refute DatabaseInternal.fetch_bank_account(entry.entity_id, acc)
    end
  end
end
