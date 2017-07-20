defmodule Helix.Process.Query.ProcessTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Account.Action.Flow.Account, as: AccountFlow
  alias Software.Decryptor.ProcessType, as: Decryptor
  alias Software.Firewall.ProcessType.Passive, as: Firewall
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Account.Factory, as: AccountFactory

  defp create_server do
    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    server
  end

  describe "get_running_processes_of_type_on_server/2" do
    test "returns what it should" do
      server = create_server()

      firewall = %{
        gateway_id: server.server_id,
        target_server_id: server.server_id,
        file_id: Random.pk(),
        process_data: %Firewall{version: 1},
        process_type: "firewall_passive"
      }

      decryptor = %{
        gateway_id: server.server_id,
        target_server_id: server.server_id,
        file_id: Random.pk(),
        process_data: %Decryptor{
          storage_id: Random.pk(),
          target_file_id: Random.pk(),
          scope: :global,
          software_version: 1
        },
        process_type: "decryptor"
      }

      {:ok, firewall1} = ProcessAction.create(firewall)
      {:ok, firewall2} = ProcessAction.create(firewall)
      {:ok, _} = ProcessAction.create(decryptor)

      expected = MapSet.new([firewall1, firewall2], &(&1.process_id))

      result =
        server.server_id
        |> ProcessQuery.get_running_processes_of_type_on_server("firewall_passive")
        |> MapSet.new(&(&1.process_id))

      assert MapSet.equal?(expected, result)

      # ProcessAction.create/1 starts the TOP machine, so we have to wait a bit
      # to gracefully stop the test
      :timer.sleep(50)
    end
  end

  describe "get_processes_on_server/1" do
    test "returns all processes on server" do
      server = create_server()

      firewall = %{
        gateway_id: server.server_id,
        target_server_id: server.server_id,
        file_id: Random.pk(),
        process_data: %Firewall{version: 1},
        process_type: "firewall_passive"
      }

      decryptor = %{
        gateway_id: server.server_id,
        target_server_id: server.server_id,
        file_id: Random.pk(),
        process_data: %Decryptor{
          storage_id: Random.pk(),
          target_file_id: Random.pk(),
          scope: :global,
          software_version: 1
        },
        process_type: "decryptor"
      }

      {:ok, _} = ProcessAction.create(firewall)
      {:ok, _} = ProcessAction.create(firewall)
      {:ok, _} = ProcessAction.create(decryptor)
      {:ok, _} = ProcessAction.create(decryptor)

      processes_on_server =
        server.server_id
        |> ProcessQuery.get_processes_on_server()
        |> Enum.count()

      assert 4 == processes_on_server

      # ProcessAction.create/1 starts the TOP machine, so we have to wait a bit
      # to gracefully stop the test
      :timer.sleep(50)
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
        file_id: Random.pk(),
        process_data: %Firewall{version: 1},
        process_type: "firewall_passive"
      }

      decryptor = %{
        gateway_id: server2.server_id,
        target_server_id: server1.server_id,
        file_id: Random.pk(),
        process_data: %Decryptor{
          storage_id: Random.pk(),
          target_file_id: Random.pk(),
          scope: :global,
          software_version: 1
        },
        process_type: "decryptor"
      }

      {:ok, _} = ProcessAction.create(firewall)
      {:ok, decryptor} = ProcessAction.create(decryptor)

      [process] = ProcessQuery.get_processes_targeting_server(server1.server_id)

      assert decryptor.process_id == process.process_id

      # ProcessAction.create/1 starts the TOP machine, so we have to wait a bit
      # to gracefully stop the test
      :timer.sleep(50)
    end
  end
end
