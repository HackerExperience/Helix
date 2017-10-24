defmodule Helix.Software.Henforcer.FileTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Software.Henforcer.File, as: FileHenforcer
  alias Helix.Software.Model.File

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "file_exists?/1" do
    test "accepts when file exists" do
      {file, _} = SoftwareSetup.file()
      assert {true, relay} = FileHenforcer.file_exists?(file.file_id)
      assert relay.file.file_id == file.file_id
    end

    test "rejects non-existing file" do
      assert {false, reason, _} = FileHenforcer.file_exists?(File.ID.generate())
      assert reason == {:file, :not_found}
    end
  end

  describe "belongs_to_server?/2" do
    test "accepts when file belongs to server" do
      {file, %{server: server}} = SoftwareSetup.file()

      assert {true, relay} =
        FileHenforcer.belongs_to_server?(file.file_id, server)

      assert relay.file == file
      assert relay.server == server
      assert relay.storage.storage_id == file.storage_id
      assert_relay relay, [:file, :server, :storage]
    end

    test "rejects when file does not belong to server" do
      {file, _} = SoftwareSetup.file()
      {server, _} = ServerSetup.server()

      assert {false, reason, _} = FileHenforcer.belongs_to_server?(file, server)
      assert reason == {:file, :not_belongs}
    end
  end

  describe "exists_software_module?/2" do
    test "accepts when module exists, returns the best; rejects otherwise"  do
      {server, _} = ServerSetup.server()

      crc1_modules =
        SoftwareHelper.generate_module(
          :cracker, %{bruteforce: 600, overflow: 200}
        )
      crc2_modules =
        SoftwareHelper.generate_module(
          :cracker, %{bruteforce: 100, overflow: 500}
        )

      {crc1, _} =
        SoftwareSetup.file(
          server_id: server.server_id, type: :cracker, modules: crc1_modules
        )
      {crc2, _} =
        SoftwareSetup.file(
          server_id: server.server_id, type: :cracker, modules: crc2_modules
        )

      # Querying for the best :bruteforce, which exists and it is `crc1`
      assert {true, relay1} =
        FileHenforcer.exists_software_module?(:bruteforce, server)
      assert relay1.file == crc1
      assert relay1.server == server

      # Querying for the best :overflow, which exists and it is `crc2`
      assert {true, relay2} =
        FileHenforcer.exists_software_module?(:overflow, server)
      assert relay2.file == crc2
      assert relay2.server == server

      # There are only `file` and `server` on the relay
      assert_relay relay1, [:file, :server]

      # Does not find a `hasher` on the server
      assert {false, reason, _} =
        FileHenforcer.exists_software_module?(:hasher, server)
      assert reason == {:module, :not_found}
    end
  end
end
