defmodule Helix.Log.Public.IndexTest do

  use Helix.Test.Case.Integration

  alias Helix.Log.Public.Index, as: LogIndex

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Log.Setup, as: LogSetup

  describe "index/1" do
    test "indexes correctly" do
      {server, _} = ServerSetup.server()

      log1 = LogSetup.log!([server_id: server.server_id, own_log: true])
      log2 = LogSetup.log!([server_id: server.server_id, own_log: true])

      index = LogIndex.index(server.server_id)

      result_log1 = Enum.find(index, &(&1.log_id == log1.log_id))
      assert result_log1.message == log1.message
      assert result_log1.timestamp == log1.creation_time

      result_log2 = Enum.find(index, &(&1.log_id == log2.log_id))
      assert result_log2.message == log2.message
      assert result_log2.timestamp == log2.creation_time
    end
  end

  describe "render_index/1" do
    test "returns JSON friendly output" do
      {server, _} = ServerSetup.server()

      log1 = LogSetup.log!([server_id: server.server_id, own_log: true])
      log2 = LogSetup.log!([server_id: server.server_id, own_log: true])

      index = LogIndex.index(server.server_id)
      rendered = LogIndex.render_index(index)

      result_log1 = Enum.find(rendered, &(&1.log_id == to_string(log1.log_id)))
      result_log2 = Enum.find(rendered, &(&1.log_id == to_string(log2.log_id)))

      assert is_binary(result_log1.log_id)
      assert is_binary(result_log2.log_id)

      assert is_binary(result_log1.timestamp)
      assert is_binary(result_log2.timestamp)
    end
  end
end
