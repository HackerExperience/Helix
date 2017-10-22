defmodule Helix.Software.Action.Flow.FileTest do

  use Helix.Test.Case.Integration

  alias Helix.Cache.Query.Cache, as: CacheQuery
  # alias Helix.Log.Action.Log, as: LogAction
  alias Helix.Software.Action.Flow.File, as: FileFlow

  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  # alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "execute_file/1" do
    test "returns error if file isn't executable" do
      {file, _} = SoftwareSetup.non_executable_file()

      assert {:error, reason} =
        FileFlow.execute_file(file, :wat, %{}, %{}, %{}, %{})
      assert reason == :not_executable
    end

    # test "Backend: Firewall" do
    #   {server, _} = ServerSetup.server()

    #   storage_id = SoftwareHelper.get_storage_id(server)
    #   {file, _} = SoftwareSetup.file(type: :firewall, storage_id: storage_id)

    #   assert {:ok, _} =
    #     FileFlow.execute_file(file, server.server_id, %{})

    #   TOPHelper.top_stop(server)
    # end

    # test "Bakend: LogForger" do
    #   {server, %{entity: entity}} = ServerSetup.server()

    #   storage_id = SoftwareHelper.get_storage_id(server)
    #  {file, _} = SoftwareSetup.file(type: :log_forger, storage_id: storage_id)

    #   {:ok, log, _} =
    #     LogAction.create(server, entity.entity_id, "Root logged in")

    #   params = %{
    #     target_log_id: log.log_id,
    #     message: "",
    #     operation: :edit,
    #     entity_id: entity.entity_id
    #   }

    #   assert {:ok, _} = FileFlow.execute_file(file, server.server_id, params)

    #   TOPHelper.top_stop(server)
    # end

    test "Backend: Cracker" do
      {source_server, _} = ServerSetup.server()
      {target_server, _} = ServerSetup.server()

      {:ok, [target_nip]} =
        CacheQuery.from_server_get_nips(target_server.server_id)

      {file, _} =
        SoftwareSetup.file([type: :cracker, server_id: source_server.server_id])

      params = %{
        target_server_ip: target_nip.ip
      }

      meta = %{
        network_id: target_nip.network_id,
        bounce: [],
        cracker: file
      }

      # Executes Cracker.bruteforce against the target server
      assert {:ok, _} =
        FileFlow.execute_file(
          file, :bruteforce, source_server, target_server, params, meta
        )

      TOPHelper.top_stop(source_server)
    end
  end
end
