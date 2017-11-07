defmodule Helix.Process.Query.ProcessTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Process.Setup, as: ProcessSetup
  alias Helix.Test.Process.TOPHelper

  describe "get_processes_on_server/1" do
    test "returns both local and remote servers" do
      {server, _} = ServerSetup.server()
      {remote, _} = ServerSetup.server()

      # Process 1 affects player's own server; started by own player; has no
      # file / connection
      process1_opts = [
        gateway_id: server.server_id,
        single_server: true,
        type: :bruteforce
      ]
      {process1, _} = ProcessSetup.process(process1_opts)

      # Process 2 affects another server; started by own player, has file and
      # connection
      process2_destination = remote.server_id
      process2_opts = [
        gateway_id: server.server_id,
        type: :file_download,
        target_id: process2_destination
      ]
      {process2, _} = ProcessSetup.process(process2_opts)

      # Process 3 affects player's own server, started by third-party.
      process3_gateway = remote.server_id
      process3_opts = [
        gateway_id: process3_gateway,
        target_id: server.server_id
      ]
      {process3, _} = ProcessSetup.process(process3_opts)

      processes = ProcessQuery.get_processes_on_server(server.server_id)

      assert length(processes) == 3

      assert Enum.find(processes, &(&1.process_id == process1.process_id))
      assert Enum.find(processes, &(&1.process_id == process2.process_id))
      assert Enum.find(processes, &(&1.process_id == process3.process_id))

      TOPHelper.top_stop()
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

      TOPHelper.top_stop()
    end

    test "returns empty list if no process is found" do
      refute ProcessQuery.get_custom("file_download", Server.ID.generate(), %{})
    end
  end
end
