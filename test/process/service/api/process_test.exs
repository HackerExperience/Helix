defmodule Helix.Process.Service.API.ProcessTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Software.Decryptor.ProcessType, as: Decryptor
  alias Software.Firewall.ProcessType.Passive, as: Firewall
  alias Helix.Process.Service.API.Process, as: API

  defp create_server do
    alias Helix.Account.Service.Flow.Account, as: AccountFlow
    alias Helix.Account.Factory, as: AccountFactory

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

      {:ok, firewall1} = API.create(firewall)
      {:ok, firewall2} = API.create(firewall)
      {:ok, _} = API.create(decryptor)

      expected = MapSet.new([firewall1, firewall2], &(&1.process_id))

      result =
        server.server_id
        |> API.get_running_processes_of_type_on_server("firewall_passive")
        |> MapSet.new(&(&1.process_id))

      assert MapSet.equal?(expected, result)

      # API.create/1 starts the TOP machine, so we have to wait a bit to
      # gracefully stop the test
      :timer.sleep(100)
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

      {:ok, _} = API.create(firewall)
      {:ok, _} = API.create(firewall)
      {:ok, _} = API.create(decryptor)
      {:ok, _} = API.create(decryptor)

      assert 4 == Enum.count(API.get_processes_on_server(server.server_id))

      # API.create/1 starts the TOP machine, so we have to wait a bit to
      # gracefully stop the test
      :timer.sleep(100)
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

      {:ok, _} = API.create(firewall)
      {:ok, decryptor} = API.create(decryptor)

      assert [process] = API.get_processes_targeting_server(server1.server_id)
      assert decryptor.process_id == process.process_id

      # API.create/1 starts the TOP machine, so we have to wait a bit to
      # gracefully stop the test
      :timer.sleep(100)
    end
  end
end
