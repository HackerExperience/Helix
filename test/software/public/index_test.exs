defmodule Helix.Software.Public.IndexTest do

  use Helix.Test.Case.Integration

  alias Helix.Software.Public.Index, as: FileIndex

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "index/1" do
    test "indexes correctly" do
      {server, _} = ServerSetup.server()

      file_opts = [server_id: server.server_id]
      [file1, file2, file3] =
        SoftwareSetup.random_files!([total: 3, file_opts: file_opts])

      index = FileIndex.index(server.server_id)

      result_file1 = Enum.find(index[file1.path], &(find_by_id(&1, file1)))
      result_file2 = Enum.find(index[file2.path], &(find_by_id(&1, file2)))
      result_file3 = Enum.find(index[file3.path], &(find_by_id(&1, file3)))

      assert result_file1.path == file1.full_path
      assert result_file1.size == file1.file_size
      assert result_file1.software_type == file1.software_type

      # TODO: This function is not testing modules
      # TODO: Test it hides hidden/encrypted files, etc.

      assert result_file2.path == file2.full_path
      assert result_file3.path == file3.full_path
    end
  end

  describe "render_index/1" do
    test "returns JSON-friendly string" do
      {server, _} = ServerSetup.server()

      file_opts = [server_id: server.server_id]
      [file1, file2, file3] =
        SoftwareSetup.random_files!([total: 3, file_opts: file_opts])

      index = FileIndex.index(server.server_id)
      rendered = FileIndex.render_index(index)

      result_file1 = Enum.find(rendered[file1.path], &(find_by_id(&1, file1)))

      assert is_binary(result_file1.file_id)
      assert is_binary(result_file1.software_type)

      assert Enum.find(rendered[file2.path], &(find_by_id(&1, file2)))
      assert Enum.find(rendered[file3.path], &(find_by_id(&1, file3)))
    end
  end

  defp find_by_id(result, expected),
    do: to_string(result.file_id) == to_string(expected.file_id)
end
