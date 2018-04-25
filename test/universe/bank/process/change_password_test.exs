defmodule Helix.Universe.Bank.Process.Bank.Account.ChangePasswordTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.Bank.Process.Bank.Account.ChangePassword,
    as: BankChangePasswordProcess

  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  @relay nil

  describe "Process.Executable" do
    test "starts a change password process when everything is OK" do
      {gateway, %{entity: entity}} = ServerSetup.server()
      bank_account = BankSetup.account!(owner_id: entity.entity_id)
      atm = ServerQuery.fetch(bank_account.atm_id)
      atm_nip = ServerHelper.get_nip(atm)

      params =
        %{
          account: bank_account,
          gateway: gateway
        }

      meta =
        %{
          network_id: atm_nip.network_id,
          bounce: nil
        }

      assert {:ok, process} =
        BankChangePasswordProcess.execute(
          gateway, atm, params, meta, @relay
        )
      assert process.src_connection_id
      assert process.type == :bank_change_password
      assert process.gateway_id == gateway.server_id
      assert process.source_entity_id == entity.entity_id
      assert process.target_id == atm.server_id
      assert process.network_id == atm_nip.network_id

      refute process.src_file_id

      connection = TunnelQuery.fetch_connection process.src_connection_id

      assert connection.connection_type == :bank_login

      tunnel = TunnelQuery.fetch(connection.tunnel_id)

      assert tunnel.gateway_id == gateway.server_id
      assert tunnel.target_id == atm.server_id
      assert tunnel.network_id == atm_nip.network_id
    end
  end
end
