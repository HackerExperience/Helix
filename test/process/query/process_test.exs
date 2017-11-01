defmodule Helix.Process.Query.ProcessTest do

  use Helix.Test.Case.Integration

  alias Helix.Account.Action.Flow.Account, as: AccountFlow
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Model.SoftwareType.Firewall.Passive, as: Firewall
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Account.Factory, as: AccountFactory
  # alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Process.Setup, as: ProcessSetup
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

      {:ok, firewall1, _} = ProcessAction.create(firewall)
      {:ok, firewall2, _} = ProcessAction.create(firewall)

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

      {:ok, _, _} = ProcessAction.create(firewall)
      {:ok, _, _} = ProcessAction.create(firewall)

      processes_on_server =
        server
        |> ProcessQuery.get_processes_on_server()
        |> Enum.count()

      assert 2 == processes_on_server

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

      firewall = %{
        gateway_id: server1.server_id,
        target_server_id: server1.server_id,
        file_id: File.ID.generate(),
        process_data: %Firewall{version: 1},
        process_type: "firewall_passive"
      }

      {:ok, _, _} = ProcessAction.create(firewall)

      [] = ProcessQuery.get_processes_targeting_server(server1.server_id)

      TOPHelper.top_stop(server1)
    end
  end

  describe "get_custom/3" do
    test "returns expected processes" do
      gateway_id = Server.ID.generate()

      {download1, _} =
        ProcessSetup.process(gateway_id: gateway_id, type: :file_download)

      # Create another process of same type, just to make sure only one is
      # returned
      ProcessSetup.process(gateway_id: gateway_id, type: :file_download)

      # Must find one process, `download1`, that matches both `type` and `meta`
      # (one process of type `download` who is downloading that specific file)
      assert [process] =
        ProcessQuery.get_custom(
          download1.type,
          gateway_id,
          %{file_id: download1.file_id}
        )

      assert process.process_id == download1.process_id

      # Cannot find that same process with random file
      refute \
        ProcessQuery.get_custom(
          download1.type,
          gateway_id,
          %{file_id: File.ID.generate()}
        )
    end

    test "returns empty list if no process is found" do
      refute ProcessQuery.get_custom("file_download", Server.ID.generate(), %{})
    end
  end
end
