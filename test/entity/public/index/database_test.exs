defmodule Helix.Entity.Public.Index.DatabaseTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Case.ID

  alias Helix.Entity.Public.Index.Database, as: DatabaseIndex

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Entity.Database.Setup, as: DatabaseSetup

  describe "index/1" do
    test "returns the expected data" do
      {entity, _} = EntitySetup.entity()

      {server1, _} = DatabaseSetup.entry_server(entity_id: entity.entity_id)
      {server2, _} =
        DatabaseSetup.entry_server(
          entity_id: entity.entity_id, password: "s3cr3t"
        )

      {bank_acc, _} =
        DatabaseSetup.entry_bank_account(entity_id: entity.entity_id)

      index = DatabaseIndex.index(entity)

      assert server1 ==
        Enum.find(index.servers, &(&1.server_ip == server1.server_ip))
      assert server2 ==
        Enum.find(index.servers, &(&1.server_ip == server2.server_ip))
      assert [bank_acc] == index.bank_accounts
    end
  end

  describe "render_index/1" do
    test "returns JSON-friendly index" do
      {entity, _} = EntitySetup.entity()

      {server1, _} = DatabaseSetup.entry_server(entity_id: entity.entity_id)
      {server2, _} =
        DatabaseSetup.entry_server(
          entity_id: entity.entity_id, password: "s3cr3t"
        )

      {bank_acc, _} =
        DatabaseSetup.entry_bank_account(entity_id: entity.entity_id)

      rendered =
        entity
        |> DatabaseIndex.index()
        |> DatabaseIndex.render_index()

      [rendered_bank_acc] = rendered.bank_accounts

      assert rendered_bank_acc.account_number == bank_acc.account_number
      assert_id rendered_bank_acc.atm_id, bank_acc.atm_id
      assert rendered_bank_acc.atm_ip == bank_acc.atm_ip
      refute rendered_bank_acc.password
      refute rendered_bank_acc.token
      refute rendered_bank_acc.notes
      refute rendered_bank_acc.known_balance
      refute rendered_bank_acc.last_login_date

      rendered_server1 =
        Enum.find(rendered.servers, &(&1.ip == server1.server_ip))
      rendered_server2 =
        Enum.find(rendered.servers, &(&1.ip == server2.server_ip))

      assert rendered_server1.ip == server1.server_ip
      assert_id rendered_server1.network_id, server1.network_id
      assert rendered_server1.type == to_string(server1.server_type)
      refute rendered_server1.notes
      refute rendered_server1.alias
      refute rendered_server1.password

      assert rendered_server2.ip == server2.server_ip
      assert_id rendered_server2.network_id, server2.network_id
      assert rendered_server2.type == to_string(server2.server_type)
      refute rendered_server2.notes
      refute rendered_server2.alias
      assert rendered_server2.password == "s3cr3t"
    end
  end
end
