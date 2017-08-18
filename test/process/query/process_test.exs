defmodule Helix.Process.Query.ProcessTest do

  use Helix.Test.Case.Integration

  alias Helix.Account.Action.Flow.Account, as: AccountFlow
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Software.Decryptor.ProcessType, as: Decryptor
  alias Helix.Software.Model.SoftwareType.Firewall.Passive, as: Firewall
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Account.Factory, as: AccountFactory
  alias Helix.Test.Process.TOPHelper

  defp create_server do
    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    CacheHelper.sync_test()

    server
  end

  describe "get_running_processes_of_type_on_server/2" do
    test "returns what it should" do
      server = create_server()

      firewall = %{
        gateway_id: server.server_id,
        target_server_id: server.server_id,
        file_id: File.ID.generate(),
        process_data: %Firewall{version: 1},
        process_type: "firewall_passive"
      }

      decryptor = %{
        gateway_id: server.server_id,
        target_server_id: server.server_id,
        file_id: File.ID.generate(),
        process_data: %Decryptor{
          storage_id: Storage.ID.generate(),
          target_file_id: File.ID.generate(),
          scope: :global,
          software_version: 1
        },
        process_type: "decryptor"
      }

      {:ok, firewall1, _} = ProcessAction.create(firewall)
      {:ok, firewall2, _} = ProcessAction.create(firewall)
      {:ok, _, _} = ProcessAction.create(decryptor)

      expected = MapSet.new([firewall1, firewall2], &(&1.process_id))

      result =
        server
        |> ProcessQuery.get_running_processes_of_type_on_server("firewall_passive")
        |> MapSet.new(&(&1.process_id))

      assert MapSet.equal?(expected, result)

      TOPHelper.top_stop(server)
    end
  end

  describe "get_processes_on_server/1" do
    test "returns all processes on server" do
      server = create_server()

      firewall = %{
        gateway_id: server.server_id,
        target_server_id: server.server_id,
        file_id: File.ID.generate(),
        process_data: %Firewall{version: 1},
        process_type: "firewall_passive"
      }

      decryptor = %{
        gateway_id: server.server_id,
        target_server_id: server.server_id,
        file_id: File.ID.generate(),
        process_data: %Decryptor{
          storage_id: Storage.ID.generate(),
          target_file_id: File.ID.generate(),
          scope: :global,
          software_version: 1
        },
        process_type: "decryptor"
      }

      {:ok, _, _} = ProcessAction.create(firewall)
      {:ok, _, _} = ProcessAction.create(firewall)
      {:ok, _, _} = ProcessAction.create(decryptor)
      {:ok, _, _} = ProcessAction.create(decryptor)

      processes_on_server =
        server
        |> ProcessQuery.get_processes_on_server()
        |> Enum.count()

      assert 4 == processes_on_server

      TOPHelper.top_stop(server)
    end
  end

  describe "get_processes_of_type_targeting_server" do
    @tag :pending
    test "returns expected external processes"
  end

  describe "get_processes_targeting_server/1" do
    test "returns processes that are not running on the gateway" do
      server1 = create_server()
      server2 = create_server()

      firewall = %{
        gateway_id: server1.server_id,
        target_server_id: server1.server_id,
        file_id: File.ID.generate(),
        process_data: %Firewall{version: 1},
        process_type: "firewall_passive"
      }

      decryptor = %{
        gateway_id: server2.server_id,
        target_server_id: server1.server_id,
        file_id: File.ID.generate(),
        process_data: %Decryptor{
          storage_id: Storage.ID.generate(),
          target_file_id: File.ID.generate(),
          scope: :global,
          software_version: 1
        },
        process_type: "decryptor"
      }

      {:ok, _, _} = ProcessAction.create(firewall)
      {:ok, decryptor, _} = ProcessAction.create(decryptor)

      [process] = ProcessQuery.get_processes_targeting_server(server1.server_id)

      assert decryptor.process_id == process.process_id

      TOPHelper.top_stop(server1)
      TOPHelper.top_stop(server2)
    end
  end
end
