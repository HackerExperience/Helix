defmodule Helix.Software.Henforcer.File.PublicFTPTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Software.Henforcer.File.PublicFTP, as: PFTPHenforcer
  alias Helix.Software.Model.File

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "pftp_exists?/1" do
    test "accepts when pftp does exist" do
      {pftp, _} = SoftwareSetup.pftp(real_server: true)

      assert {true, relay} = PFTPHenforcer.pftp_exists?(pftp.server_id)
      assert relay.pftp == pftp
      assert relay.server.server_id == pftp.server_id

      assert_relay relay, [:pftp, :server]
    end

    test "accepts regardless of the pftp status (enabled/disabled)" do
      {pftp, _} = SoftwareSetup.pftp(real_server: true, active: false)

      assert {true, relay} = PFTPHenforcer.pftp_exists?(pftp.server_id)
      assert relay.pftp == pftp
    end

    test "rejects when underlying server cant be found" do
      {pftp, _} = SoftwareSetup.pftp(real_server: false)

      assert {false, reason, _} = PFTPHenforcer.pftp_exists?(pftp.server_id)
      assert reason == {:server, :not_found}
    end

    test "rejects when server exists but pftp doesnt" do
      {server, _} = ServerSetup.server()

      assert {false, reason, _} = PFTPHenforcer.pftp_exists?(server.server_id)
      assert reason == {:pftp, :not_found}
    end
  end

  describe "file_exists?/2" do
    test "accepts when file exists on pftp" do
      {pftp, _} = SoftwareSetup.pftp(real_server: true)
      {pftp_file, %{file: file}} =
        SoftwareSetup.pftp_file(server_id: pftp.server_id)

      server_id = pftp_file.server_id
      file_id = pftp_file.file_id

      assert {true, relay} = PFTPHenforcer.file_exists?(server_id, file_id)
      assert relay.file == file
      assert relay.pftp_file == pftp_file
      assert relay.server.server_id == server_id

      assert_relay relay, [:file, :pftp_file, :server]
    end

    test "rejects when pftp is disabled" do
      {pftp, _} = SoftwareSetup.pftp(real_server: true, active: false)
      {pftp_file, _} = SoftwareSetup.pftp_file(server_id: pftp.server_id)

      server_id = pftp_file.server_id
      file_id = pftp_file.file_id

      assert {false, reason, _} = PFTPHenforcer.file_exists?(server_id, file_id)
      assert reason == {:pftp_file, :not_found}
    end

    test "rejects when file exists but not on pftp" do
      {file, %{server_id: server_id}} = SoftwareSetup.file()

      assert {false, reason, _} =
        PFTPHenforcer.file_exists?(server_id, file.file_id)
      assert reason == {:pftp_file, :not_found}
    end

    test "rejects when file does not exist" do
      {pftp, _} = SoftwareSetup.pftp()

      assert {false, reason, _} =
        PFTPHenforcer.file_exists?(pftp.server_id, File.ID.generate())

      assert reason == {:file, :not_found}
    end
  end

  describe "pftp_enabled?/1 and pftp_disabled?/1" do
    test "when pftp is enabled (with PublicFTP.t)" do
      {pftp, _} = SoftwareSetup.fake_pftp(active: true)

      assert {true, %{}} == PFTPHenforcer.pftp_enabled?(pftp)

      assert {false, reason, _} = PFTPHenforcer.pftp_disabled?(pftp)
      assert reason == {:pftp, :enabled}
    end

    test "when pftp is enabled (with Server.idt)" do
      {pftp, _} = SoftwareSetup.pftp(active: true, real_server: true)

      assert {true, relay} = PFTPHenforcer.pftp_enabled?(pftp.server_id)
      assert relay.pftp == pftp
      assert relay.server.server_id == pftp.server_id
      assert_relay relay, [:pftp, :server]
    end

    test "when pftp is disabled (with PublicFTP.t)" do
      {pftp, _} = SoftwareSetup.fake_pftp(active: false)

      assert {true, %{}} == PFTPHenforcer.pftp_disabled?(pftp)

      assert {false, reason, _} = PFTPHenforcer.pftp_enabled?(pftp)
      assert reason == {:pftp, :disabled}
    end

    test "when pftp is disabled (with Server.idt)" do
      {pftp, _} = SoftwareSetup.pftp(active: false, real_server: true)

      assert {true, relay} = PFTPHenforcer.pftp_disabled?(pftp.server_id)
      assert relay.pftp == pftp
      assert relay.server.server_id == pftp.server_id
      assert_relay relay, [:pftp, :server]
    end
  end

  describe "can_add_file?/3" do
    test "accepts when player can add file" do
      {server, %{entity: entity}} = ServerSetup.server()
      {_pftp, _} = SoftwareSetup.pftp(server_id: server.server_id)
      {file, _} = SoftwareSetup.file(server_id: server.server_id)

      assert {true, relay} =
        PFTPHenforcer.can_add_file?(
          entity.entity_id,
          server.server_id,
          file.file_id
        )

      assert relay.entity == entity
      assert relay.storage.storage_id == file.storage_id

      assert_relay relay, [:file, :pftp, :server, :entity, :storage]
    end

    test "rejects when file is already added to the public ftp" do
      {server, %{entity: entity}} = ServerSetup.server()
      {_pftp, _} = SoftwareSetup.pftp(server_id: server.server_id)
      {pftp_file, _} = SoftwareSetup.pftp_file(server_id: server.server_id)

      assert {false, reason, _} =
        PFTPHenforcer.can_add_file?(
          entity.entity_id,
          server.server_id,
          pftp_file.file_id
        )
      assert reason == {:file, :exists}
    end

    test "rejects when player is not owner of server" do
      {pftp, _} = SoftwareSetup.pftp(real_server: true)
      {file, _} = SoftwareSetup.file(server_id: pftp.server_id)
      {entity, _} = EntitySetup.entity()

      assert {false, reason, _} =
        PFTPHenforcer.can_add_file?(
          entity.entity_id,
          pftp.server_id,
          file.file_id
        )
      assert reason == {:server, :not_belongs}
    end

    test "rejects when file does not belong to server" do
      {server, %{entity: entity}} = ServerSetup.server()
      {pftp, _} = SoftwareSetup.pftp(server_id: server.server_id)
      {file, _} = SoftwareSetup.file()

      assert {false, reason, _} =
        PFTPHenforcer.can_add_file?(
          entity.entity_id,
          pftp.server_id,
          file.file_id
        )
      assert reason == {:file, :not_belongs}
    end
  end

  describe "can_remove_file?/3" do
    test "accepts when player can remove file" do
      {server, %{entity: entity}} = ServerSetup.server()
      {_pftp, _} = SoftwareSetup.pftp(server_id: server.server_id)
      {pftp_file, _} = SoftwareSetup.pftp_file(server_id: server.server_id)

      assert {true, relay} =
        PFTPHenforcer.can_remove_file?(
          entity.entity_id,
          server.server_id,
          pftp_file.file_id
        )

      assert relay.pftp_file == pftp_file
      assert relay.entity == entity
      assert relay.server == server

      assert_relay relay, [:file, :pftp, :pftp_file, :server, :entity]
    end

    test "rejects when file does not exist on public ftp" do
      {server, %{entity: entity}} = ServerSetup.server()
      {_pftp, _} = SoftwareSetup.pftp(server_id: server.server_id)
      {file, _} = SoftwareSetup.file(server_id: server.server_id)

      assert {false, reason, _} =
        PFTPHenforcer.can_remove_file?(
          entity.entity_id,
          server.server_id,
          file.file_id
        )

      assert reason == {:pftp_file, :not_found}
    end

    test "rejects when public ftp isn't enabled" do
      {server, %{entity: entity}} = ServerSetup.server()
      {_, _} = SoftwareSetup.pftp(server_id: server.server_id, active: false)
      {pftp_file, _} = SoftwareSetup.pftp_file(server_id: server.server_id)

      assert {false, reason, _} =
        PFTPHenforcer.can_remove_file?(
          entity.entity_id,
          server.server_id,
          pftp_file.file_id
        )

      assert reason == {:pftp, :disabled}
    end

    test "rejects when server does not belong to the entity" do
      {pftp, _} = SoftwareSetup.pftp(real_server: true)
      {pftp_file, _} = SoftwareSetup.pftp_file(server_id: pftp.server_id)
      {entity, _} = EntitySetup.entity()

      assert {false, reason, _} =
        PFTPHenforcer.can_remove_file?(
          entity.entity_id,
          pftp.server_id,
          pftp_file.file_id
        )
      assert reason == {:server, :not_belongs}
    end
  end

  describe "can_enable_server?/2" do
    test "accepts when everything is valid" do
      {server, %{entity: entity}} = ServerSetup.server()

      assert {true, relay} =
        PFTPHenforcer.can_enable_server?(entity.entity_id, server.server_id)

      assert relay.entity == entity
      assert relay.server == server

      assert_relay relay, [:entity, :server]
    end

    test "rejects if the server is already enabled" do
      {server, %{entity: entity}} = ServerSetup.server()
      {_, _} = SoftwareSetup.pftp(server_id: server.server_id)

      assert {false, reason, _} =
        PFTPHenforcer.can_enable_server?(entity.entity_id, server.server_id)
      assert reason == {:pftp, :enabled}
    end

    test "rejects if the entity does not own that server" do
      {server, _} = ServerSetup.server()
      {entity, _} = EntitySetup.entity()

      assert {false, reason, _} =
        PFTPHenforcer.can_enable_server?(entity.entity_id, server.server_id)
      assert reason == {:server, :not_belongs}
    end
  end

  describe "can_disable_server?/2" do
    test "accepts when everything is valid" do
      {server, %{entity: entity}} = ServerSetup.server()
      {pftp, _} = SoftwareSetup.pftp(server_id: server.server_id)

      assert {true, relay} =
        PFTPHenforcer.can_disable_server?(entity.entity_id, server.server_id)

      assert relay.pftp == pftp
      assert relay.entity == entity
      assert relay.server == server

      assert_relay relay, [:server, :entity, :pftp]
    end
  end
end
