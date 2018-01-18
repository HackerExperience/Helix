defmodule Helix.Software.Public.PFTPTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Software.Public.PFTP, as: PFTPPublic

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @internet_id NetworkHelper.internet_id()
  @relay nil

  describe "download/4" do
    test "starts a pftp download process" do
      {gateway, _} = ServerSetup.server()
      {pftp, _} = SoftwareSetup.PFTP.pftp(real_server: true)
      {_, %{file: file}} = SoftwareSetup.PFTP.file(server_id: pftp.server_id)

      destination = ServerQuery.fetch(pftp.server_id)
      storage = SoftwareHelper.get_storage(pftp.server_id)

      assert {:ok, process} =
        PFTPPublic.download(
          gateway, destination, storage, file, @internet_id, @relay
        )

      assert process.gateway_id == gateway.server_id
      assert process.target_id == pftp.server_id
      assert process.tgt_file_id == file.file_id
      assert process.type == :file_download
      assert process.src_connection_id
      assert process.data.connection_type == :public_ftp

      refute process.src_file_id
      refute process.tgt_connection_id

      TOPHelper.top_stop(gateway)
    end
  end

  describe "list_files/1" do
    test "returns all files on a PFTP server" do
      {pftp, _} = SoftwareSetup.PFTP.pftp(real_server: true)

      # There's nothing there
      assert [] == PFTPPublic.list_files(pftp)

      # Let's try again with one file
      {_, %{file: file1}} = SoftwareSetup.PFTP.file(server_id: pftp.server_id)

      assert [entry1] = PFTPPublic.list_files(pftp)
      assert entry1 == file1

      # And yet another one
      {_, %{file: file2}} = SoftwareSetup.PFTP.file(server_id: pftp.server_id)
      pftp_files = PFTPPublic.list_files(pftp)

      assert Enum.sort([file1, file2]) == Enum.sort(pftp_files)
    end
  end

  describe "render_list_file/1" do
    test "returns a correct, json-friendly format" do
      {pftp, _} = SoftwareSetup.PFTP.pftp(real_server: true)

      # Generating a cracker so we know for sure it has modules and which ones
      {crc, _} = SoftwareSetup.cracker(server_id: pftp.server_id)
      SoftwareSetup.PFTP.file(server_id: pftp.server_id, file_id: crc.file_id)

      assert [rendered] =
        pftp
        |> PFTPPublic.list_files()
        |> PFTPPublic.render_list_files()

      assert rendered.id == to_string(crc.file_id)
      assert rendered.name == crc.name
      assert rendered.type == to_string(crc.software_type)

      crc_modules = crc.modules |> Map.keys() |> Enum.map(&to_string/1)

      Enum.each(rendered.modules, fn {module, data} ->
        assert module in crc_modules
        assert data.version == crc.modules[String.to_atom(module)].version
      end)
    end
  end
end
