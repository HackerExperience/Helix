defmodule Helix.Software.Action.Flow.FileTest do

  use Helix.Test.Case.Integration

  alias Helix.Account.Action.Flow.Account, as: AccountFlow
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Log.Action.Log, as: LogAction
  alias Helix.Log.Model.Log
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Software.Action.Flow.File, as: FileFlow
  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Model.SoftwareType.Firewall.Passive, as: FirewallPassive
  alias Helix.Software.Model.SoftwareType.LogForge
  alias Helix.Software.Query.Storage, as: StorageQuery

  alias Helix.Test.Account.Factory, as: AccountFactory
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Factory
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "firewall" do
    test "starts firewall process on success" do
      account = AccountFactory.insert(:account)

      {:ok, %{server: server}} = AccountFlow.setup_account(account)

      CacheHelper.sync_test()

      {:ok, storages} = CacheQuery.from_server_get_storages(server)
      storage = storages |> Enum.random() |> StorageQuery.fetch()

      file = Factory.insert(:file, software_type: :firewall, storage: storage)
      modules = %{firewall_passive: 100}
      # FIXME: this function should exist on the FileAction
      FileInternal.set_modules(file, modules)

      result = FileFlow.execute_file(file, server, %{})
      assert {:ok, process} = result
      assert %FirewallPassive{} = process.process_data
      assert "firewall_passive" == process.process_type

      TOPHelper.top_stop(server)
    end
  end

  describe "log_forger 'edit' operation" do
    test "fails if target log doesn't exist" do
      account = AccountFactory.insert(:account)

      {:ok, %{server: server}} = AccountFlow.setup_account(account)

      CacheHelper.sync_test()

      {:ok, storages} = CacheQuery.from_server_get_storages(server)
      storage = storages |> Enum.random() |> StorageQuery.fetch()

      file = Factory.insert(:file, software_type: :log_forger, storage: storage)
      params = %{
        target_log_id: Log.ID.generate(),
        message: "I say hey hey",
        operation: "edit",
        entity_id: EntityQuery.get_entity_id(account)
      }

      result = FileFlow.execute_file(file, server, params)
      assert {:error, {:log, :notfound}} == result
    end

    test "starts log_forger process on success" do
      account = AccountFactory.insert(:account)

      {:ok, %{server: server}} = AccountFlow.setup_account(account)

      CacheHelper.sync_test()

      {:ok, storages} = CacheQuery.from_server_get_storages(server)
      storage = storages |> Enum.random() |> StorageQuery.fetch()

      entity_id = EntityQuery.get_entity_id(account)

      {:ok, log, _} = LogAction.create(server, entity_id, "Root logged in")
      file = Factory.insert(:file, software_type: :log_forger, storage: storage)
      modules = %{log_forger_create: 100, log_forger_edit: 100}
      # FIXME: this function should exist on the FileAction
      FileInternal.set_modules(file, modules)

      params = %{
        target_log_id: log.log_id,
        message: "",
        operation: "edit",
        entity_id: entity_id
      }

      result = FileFlow.execute_file(file, server, params)
      assert {:ok, process} = result
      assert %LogForge{} = process.process_data
      assert "log_forger" == process.process_type

      TOPHelper.top_stop(server)
    end
  end

  describe "log_forger 'create' operation" do
    test "starts log_forger process on success" do
      account = AccountFactory.insert(:account)

      {:ok, %{server: server}} = AccountFlow.setup_account(account)

      CacheHelper.sync_test()

      {:ok, storages} = CacheQuery.from_server_get_storages(server)
      storage = storages |> Enum.random() |> StorageQuery.fetch()

      entity_id = EntityQuery.get_entity_id(account)

      file = Factory.insert(:file, software_type: :log_forger, storage: storage)
      modules = %{log_forger_create: 100, log_forger_edit: 100}
      # FIXME: this function should exist on the FileAction
      FileInternal.set_modules(file, modules)

      params = %{
        target_server_id: server,
        message: "",
        operation: "create",
        entity_id: entity_id
      }

      result = FileFlow.execute_file(file, server, params)
      assert {:ok, process} = result
      assert %LogForge{} = process.process_data
      assert "log_forger" == process.process_type

      TOPHelper.top_stop(server)
    end
  end

  describe "execute_file for cracker bruteforce attack" do
    test "starts the bruteforce process when everything is OK" do
      {source_server, %{entity: source_entity}} = ServerSetup.server()
      {target_server, _} = ServerSetup.server()

      {:ok, [target_nip]} =
        CacheQuery.from_server_get_nips(target_server.server_id)

      {file, _} =
        SoftwareSetup.file([type: :cracker, server_id: source_server.server_id])

      params = %{
        source_entity_id: source_entity.entity_id,
        target_server_id: target_server.server_id,
        network_id: target_nip.network_id,
        target_server_ip: target_nip.ip
      }

      meta = %{
        bounces: []
      }

      # Executes Cracker.bruteforce against the target server
      assert {:ok, process} =
        FileFlow.execute_file(file, source_server, params, meta)

      # Process data is correct
      assert process.connection_id
      assert process.file_id == file.file_id
      assert process.process_type == "cracker_bruteforce"
      assert process.gateway_id == source_server.server_id
      assert process.process_data.source_entity_id == source_entity.entity_id
      assert process.process_data.target_server_id == target_server.server_id
      assert process.process_data.network_id == target_nip.network_id
      assert process.process_data.target_server_ip == target_nip.ip

      # CrackerBruteforce connection is correct
      connection = TunnelQuery.fetch_connection(process.connection_id)

      assert connection.connection_type == :cracker_bruteforce

      # Underlying tunnel is correct
      tunnel = TunnelQuery.fetch(connection.tunnel_id)

      assert tunnel.gateway_id == source_server.server_id
      assert tunnel.destination_id == target_server.server_id
      assert tunnel.network_id == target_nip.network_id

      TOPHelper.top_stop(source_server)
    end
  end
end
