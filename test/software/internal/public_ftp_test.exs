defmodule Helix.Software.Internal.PublicFTPTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Model.Server
  alias Helix.Software.Internal.PublicFTP, as: PublicFTPInternal
  alias Helix.Software.Model.PublicFTP

  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "fetch/1" do
    test "returns the pftp server if found" do
      {pftp, _} = SoftwareSetup.PFTP.pftp()

      entry  = PublicFTPInternal.fetch(pftp.server_id)
      assert entry == pftp
    end

    test "fetches pftp server even if it is disabled" do
      {pftp, _} = SoftwareSetup.PFTP.pftp(active: false)
      refute pftp.is_active

      entry  = PublicFTPInternal.fetch(pftp.server_id)
      assert entry == pftp
    end

    test "returns nil if nothing was found" do
      refute PublicFTPInternal.fetch(Server.ID.generate())
    end
  end

  describe "fetch_file/1" do
    test "returns the corresponding PublicFTP.File entry if found" do
      {pftp, _} = SoftwareSetup.PFTP.pftp(real_server: true)
      {pftp_file, _} = SoftwareSetup.PFTP.file(server_id: pftp.server_id)

      entry = PublicFTPInternal.fetch_file(pftp_file.file_id)
      assert entry == pftp_file
    end

    test "does not fetch the file if the server is disabled" do
      {pftp, _} = SoftwareSetup.PFTP.pftp(active: false, real_server: true)
      {pftp_file, _} = SoftwareSetup.PFTP.file(server_id: pftp.server_id)

      refute PublicFTPInternal.fetch_file(pftp_file.file_id)
    end
  end

  describe "list_files/1" do
    test "returns all files as File.t" do
      {pftp, _} = SoftwareSetup.PFTP.pftp(active: true, real_server: true)

      server_id = pftp.server_id

      {file1, _} = SoftwareSetup.file(server_id: server_id)
      {file2, _} = SoftwareSetup.file(server_id: server_id)
      {file3, _} = SoftwareSetup.file(server_id: server_id)

      SoftwareSetup.PFTP.file(server_id: server_id, file_id: file1.file_id)
      SoftwareSetup.PFTP.file(server_id: server_id, file_id: file2.file_id)
      SoftwareSetup.PFTP.file(server_id: server_id, file_id: file3.file_id)

      files = PublicFTPInternal.list_files(pftp.server_id)

      assert is_list(files) and length(files) == 3
      assert Enum.sort(files) == Enum.sort([file1, file2, file3])
    end

    test "returns nothing if server is disabled" do
      {pftp, _} = SoftwareSetup.PFTP.pftp(active: false, real_server: true)
      {_, _} = SoftwareSetup.PFTP.file(server_id: pftp.server_id)

      # Got nothing, even though there is a file there.
      assert [] == PublicFTPInternal.list_files(pftp.server_id)
    end
  end

  describe "setup_server/1" do
    test "creates the PublicFTP entry" do
      assert {:ok, entry} = PublicFTPInternal.setup_server(Server.ID.generate())
      assert %PublicFTP{} = entry
      assert entry.is_active
    end
  end

  describe "enable_server/1" do
    test "enables an otherwise disabled server" do
      {pftp, _} = SoftwareSetup.PFTP.pftp(active: false)
      refute pftp.is_active

      assert {:ok, new_pftp} = PublicFTPInternal.enable_server(pftp)
      assert new_pftp.is_active
      assert new_pftp.server_id == pftp.server_id
    end
  end

  describe "disable_server/1" do
    test "disables an otherwise enabled server" do
      {pftp, _} = SoftwareSetup.PFTP.pftp(active: true)
      assert pftp.is_active

      assert {:ok, new_pftp} = PublicFTPInternal.disable_server(pftp)
      refute new_pftp.is_active
      assert new_pftp.server_id == pftp.server_id
    end
  end

  describe "add_file/2" do
    test "adds file to the server" do
      {pftp, _} = SoftwareSetup.PFTP.pftp(active: true, real_server: true)
      {file, _} = SoftwareSetup.file(server_id: pftp.server_id)

      assert {:ok, pftp_file} = PublicFTPInternal.add_file(pftp, file.file_id)
      assert pftp_file.file_id == file.file_id
      assert pftp_file.server_id == pftp.server_id
    end
  end

  describe "remove_file/2" do
    test "removes file from the server" do
      {pftp, _} = SoftwareSetup.PFTP.pftp(real_server: true)
      {pftp_file, _} = SoftwareSetup.PFTP.file(server_id: pftp.server_id)

      total = length(PublicFTPInternal.list_files(pftp_file.server_id))
      assert total == 1

      assert {:ok, removed} = PublicFTPInternal.remove_file(pftp_file)
      assert removed.file_id == pftp_file.file_id
      assert removed.server_id == pftp_file.server_id
      assert removed.__meta__.state == :deleted

      total = length(PublicFTPInternal.list_files(pftp_file.server_id))
      assert total == 0
    end
  end
end
