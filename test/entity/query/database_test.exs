defmodule Helix.Entity.Query.DatabaseTest do

  use Helix.Test.IntegrationCase

  alias Helix.Entity.Query.Database, as: DatabaseQuery

  alias Helix.Test.Entity.Database.Setup, as: DatabaseSetup

  describe "get_server_password/3" do
    test "returns the stored password when entry exists" do
      expected = "phoebegata"
      entry = DatabaseSetup.entry_server([password: expected])

      database_password =
        DatabaseQuery.get_server_password(
          entry.entity_id,
          entry.network_id,
          entry.server_ip)

      assert database_password == expected
    end

    test "returns empty when entry exists but password is unknown" do
      entry = DatabaseSetup.entry_server()

      password =
        DatabaseQuery.get_server_password(
          entry.entity_id,
          entry.network_id,
          entry.server_ip)

      refute password
    end

    test "returns empty when entry does not exist" do
      fake_entry = DatabaseSetup.fake_entry_server()

      password =
        DatabaseQuery.get_server_password(
          fake_entry.entity_id,
          fake_entry.network_id,
          fake_entry.server_ip)

      refute password
    end
  end
end
