defmodule Helix.Process.Public.IndexTest do

  use Helix.Test.Case.Integration

  alias Helix.Process.Public.Index, as: ProcessIndex

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Process.Setup, as: ProcessSetup
  alias Helix.Test.Process.TOPHelper

  describe "index/1" do
    test "indexes correctly" do
      {server, %{entity: entity}} = ServerSetup.server()
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

      index = ProcessIndex.index(server.server_id, entity.entity_id)

      # There are three processes total
      assert length(index) == 3

      result_process1 = Enum.find(index, &(find_by_id(&1, process1)))
      result_process2 = Enum.find(index, &(find_by_id(&1, process2)))
      result_process3 = Enum.find(index, &(find_by_id(&1, process3)))

      # Result comes in binary format
      assert is_binary(result_process1.process_id)
      assert is_binary(result_process1.access.origin_ip)
      assert is_binary(result_process1.target_ip)
      assert is_binary(result_process1.state)
      assert is_binary(result_process1.network_id)
      assert is_binary(result_process1.type)

      # Nil values are nil (not "")
      refute result_process1.access.source_connection_id

      # Process2 has file data, connection_id
      assert is_binary(result_process2.target_file.id)
      assert is_binary(result_process2.target_file.name)
      assert is_binary(result_process2.access.source_connection_id)

      # Process2 does not have origin file
      assert Enum.empty?(result_process2.access.source_file)

      # Process3 is listed as well
      assert result_process3

      # Process3 is partial, i.e. I have limited information about it.
      # For instance, I don't know who started it
      refute Map.has_key?(result_process3.access, :origin_ip)

      TOPHelper.top_stop(server.server_id)
    end
  end

  defp find_by_id(result, wanted),
    do: result.process_id == to_string(wanted.process_id)
end
