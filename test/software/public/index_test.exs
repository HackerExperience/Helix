defmodule Helix.Software.Public.IndexTest do

  use Helix.Test.Case.Integration

  alias Helix.Software.Internal.Virus, as: VirusInternal
  alias Helix.Software.Public.Index, as: FileIndex

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "index/1" do
    # TODO: Test it hides hidden/encrypted files, etc.
    test "indexes correctly" do
      {server, _} = ServerSetup.server()

      file_opts = [server_id: server.server_id]
      [file1, file2, file3] =
        SoftwareSetup.random_files!([total: 3, file_opts: file_opts])

      # Add `file4` which is on the same path as `file3`
      file4 = SoftwareSetup.file!(file_opts ++ [path: file3.path])

      index = FileIndex.index(server.server_id)

      storage_id = file1.storage_id
      filesystem = index[storage_id].filesystem

      result_file1 = Enum.find(filesystem[file1.path], &(find_by_id(&1, file1)))
      result_file2 = Enum.find(filesystem[file2.path], &(find_by_id(&1, file2)))
      result_file3 = Enum.find(filesystem[file3.path], &(find_by_id(&1, file3)))
      result_file4 = Enum.find(filesystem[file4.path], &(find_by_id(&1, file4)))

      assert result_file1 == file1
      assert result_file2 == file2
      assert result_file3 == file3
      assert result_file4 == file4

      # Also returned the name of the filesystem
      assert is_binary(index[storage_id].name)
    end

    test "returns file metadata" do
      {server, _} = ServerSetup.server()

      file_opts = [server_id: server.server_id]
      virus1 = SoftwareSetup.file!(file_opts ++ [type: :virus_spyware])
      virus2 = SoftwareSetup.file!(file_opts ++ [type: :virus_spyware])

      # `virus2` is installed
      VirusInternal.install(virus2, EntitySetup.id())

      index = FileIndex.index(server.server_id)

      storage_id = virus1.storage_id
      filesystem = index[storage_id].filesystem

      result_v1 = Enum.find(filesystem[virus1.path], &(find_by_id(&1, virus1)))
      result_v2 = Enum.find(filesystem[virus2.path], &(find_by_id(&1, virus2)))

      # `virus1` isn't installed; `virus2` is
      refute result_v1.meta.installed?
      assert result_v2.meta.installed?
    end
  end

  describe "render_index/1" do
    test "returns JSON-friendly string" do
      {server, _} = ServerSetup.server()

      file_opts = [server_id: server.server_id]
      [file1, file2, file3] =
        SoftwareSetup.random_files!([total: 3, file_opts: file_opts])

      # `file4` is a virus that's installed on the filesystem. Nasty!
      file4 = SoftwareSetup.file!(file_opts ++ [type: :virus_spyware])
      VirusInternal.install(file4, EntitySetup.id())

      # Render index
      index = FileIndex.index(server.server_id)
      rendered = FileIndex.render_index(index)

      # Fetch rendered filesystem from the index
      storage_id = file1.storage_id
      rendered_fs = rendered[to_string(storage_id)].filesystem

      result_f1 = Enum.find(rendered_fs[file1.path], &(find_by_id(&1, file1)))
      result_f4 = Enum.find(rendered_fs[file4.path], &(find_by_id(&1, file4)))

      assert is_binary(result_f1.id)
      assert is_binary(result_f1.type)
      assert is_map(result_f1.modules)
      assert is_map(result_f1.meta)

      # Rendered metadata for `file4`
      assert result_f4.meta.installed?

      assert Enum.find(rendered_fs[file2.path], &(find_by_id(&1, file2)))
      assert Enum.find(rendered_fs[file3.path], &(find_by_id(&1, file3)))

      # Also rendered storage name
      assert is_binary(rendered[to_string(storage_id)].name)
    end
  end

  defp find_by_id(result = %{file_id: _}, expected),
    do: result.file_id == expected.file_id
  defp find_by_id(result, expected),
    do: result.id == to_string(expected.file_id)
end
