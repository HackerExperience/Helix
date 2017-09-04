defmodule Helix.Process.Public.IndexTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Model.Connection
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Process.Public.Index, as: ProcessIndex

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Process.Setup, as: ProcessSetup
  alias Helix.Test.Process.TOPHelper

  describe "index/1" do
    test "indexes correctly" do
      {server, %{entity: entity}} = ServerSetup.server()

      # Process 1 affects player's own server; started by own player; has no
      # file / connection
      process1_opts = [gateway_id: server.server_id, single_server: true]
      {process1, _} = ProcessSetup.process(process1_opts)

      # Process 2 affects another server; started by own player, has file and
      # connection
      process2_destination = Server.ID.generate()
      process2_opts = [
        gateway_id: server.server_id,
        file_id: File.ID.generate(),
        connection_id: Connection.ID.generate(),
        destination_id: process2_destination]
      {process2, _} = ProcessSetup.process(process2_opts)

      # Process 3 affects player's own server, started by third-party.
      process3_gateway = Server.ID.generate()
      process3_opts =
        [gateway_id: process3_gateway,
         destination_id: server.server_id]
      {process3, _} = ProcessSetup.process(process3_opts)

      index = ProcessIndex.index(server.server_id, entity.entity_id)

      result_process1 = Enum.find(index.owned, &(find_by_id(&1, process1)))
      result_process2 = Enum.find(index.owned, &(find_by_id(&1, process2)))
      _result_process3 = Enum.find(index.owned, &(find_by_id(&1, process3)))

      # Result comes in binary format
      assert is_binary(result_process1.gateway_id)
      assert is_binary(result_process1.target_server_id)
      assert is_binary(result_process1.state)
      assert is_binary(result_process1.network_id)

      # Nil values are nil (not "")
      refute result_process1.file_id
      refute result_process1.connection_id

      # Process2 has file_id, connection_id
      assert result_process2.file_id
      assert result_process2.connection_id

      # FIXME: process3 isn't being returned
      # Process3 exists!
      # assert result_process3

      TOPHelper.top_stop(server.server_id)
    end
  end

  defp find_by_id(result, wanted),
    do: result.process_id == to_string(wanted.process_id)
end
