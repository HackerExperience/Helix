defmodule Helix.Software.Public.FileTest do

  use Helix.Test.Case.Integration

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Software.Public.File, as: FilePublic

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @relay nil

  describe "bruteforce/6" do
    test "starts a bruteforce attack" do
      {source_server, %{entity: source_entity}} = ServerSetup.server()
      {target_server, _} = ServerSetup.server()

      {:ok, [target_nip]} =
        CacheQuery.from_server_get_nips(target_server.server_id)

      {cracker, _} =
        SoftwareSetup.file([type: :cracker, server_id: source_server.server_id])

      # Start the process from public
      assert {:ok, process} =
        FilePublic.bruteforce(
          cracker,
          source_server,
          target_server,
          {target_nip.network_id, target_nip.ip},
          nil,
          @relay
        )

      assert process.src_connection_id
      assert process.gateway_id == source_server.server_id
      assert process.target_id == target_server.server_id
      assert process.network_id == target_nip.network_id
      assert process.src_file_id == cracker.file_id
      assert process.source_entity_id == source_entity.entity_id
      assert process.data.target_server_ip == target_nip.ip

      refute process.tgt_file_id
      refute process.tgt_connection_id

      TOPHelper.top_stop(source_server.server_id)
      CacheHelper.sync_test()
    end
  end

  describe "download/5" do
    test "starts download process" do
      {gateway, _} = ServerSetup.server()
      {destination, _} = ServerSetup.server()
      {file, _} = SoftwareSetup.file(server_id: destination.server_id)

      {tunnel, _} =
        NetworkSetup.tunnel(
          gateway_id: gateway.server_id,
          destination_id: destination.server_id
        )

      storage = SoftwareHelper.get_storage(destination)

      assert {:ok, process} =
        FilePublic.download(gateway, destination, tunnel, storage, file, @relay)

      assert process.tgt_file_id == file.file_id
      assert process.type == :file_download
      assert process.data.connection_type == :ftp
      assert process.data.type == :download

      refute process.src_file_id
      refute process.tgt_connection_id

      TOPHelper.top_stop(gateway)
    end
  end

  describe "upload/5" do
    test "starts upload process" do
      {gateway, _} = ServerSetup.server()
      {destination, _} = ServerSetup.server()
      {file, _} = SoftwareSetup.file(server_id: gateway.server_id)

      {tunnel, _} =
        NetworkSetup.tunnel(
          gateway_id: gateway.server_id,
          destination_id: destination.server_id
        )

      storage = SoftwareHelper.get_storage(gateway)

      assert {:ok, process} =
        FilePublic.upload(gateway, destination, tunnel, storage, file, @relay)

      assert process.tgt_file_id == file.file_id
      assert process.type == :file_upload
      assert process.data.connection_type == :ftp
      assert process.data.type == :upload

      refute process.src_file_id
      refute process.tgt_connection_id

      TOPHelper.top_stop(gateway)
    end
  end

  describe "install/5" do
    test "starts install process (backend: virus)" do
      {gateway, _} = ServerSetup.server()
      {target, _} = ServerSetup.server()
      virus = SoftwareSetup.file!(type: :virus_spyware)

      {tunnel, _} = NetworkSetup.tunnel()
      {ssh, _} = NetworkSetup.connection(type: :ssh)

      assert {:ok, process} =
        FilePublic.install(
          virus, gateway, target, :virus, {tunnel, ssh}, @relay
        )

      assert process.tgt_file_id == virus.file_id
      assert process.gateway_id == gateway.server_id
      assert process.target_id == target.server_id
      assert process.network_id == tunnel.network_id
      assert process.src_connection_id == ssh.connection_id

      refute process.src_file_id
      refute process.tgt_connection_id

      assert process.data.backend == :virus

      TOPHelper.top_stop(gateway)
    end
  end
end
