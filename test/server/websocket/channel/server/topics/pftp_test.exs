defmodule Helix.Server.Websocket.Channel.Server.Topics.PFTPTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Software.Model.PublicFTP
  alias Helix.Software.Query.PublicFTP, as: PublicFTPQuery

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @internet_id NetworkHelper.internet_id()

  describe "pftp.server.enable" do
    test "enables a server" do
      {socket, %{gateway: server}} = ChannelSetup.join_server(own_server: true)

      # I have no PublicFTP server :(
      refute PublicFTPQuery.fetch_server(server)

      # Make the request
      ref = push socket, "pftp.server.enable", %{}

      # Wait for the response, which is empty (but :ok)
      assert_reply ref, :ok, response, timeout()
      assert response.data == %{}

      # I have a PublicFTP server :)
      assert PublicFTPQuery.fetch_server(server)
    end
  end

  describe "pftp.server.disable" do
    test "disables a server" do
      {socket, %{gateway: server}} = ChannelSetup.join_server(own_server: true)
      SoftwareSetup.PFTP.pftp(server_id: server.server_id)

      # I have a PFTP server
      assert PublicFTPQuery.fetch_server(server)

      # Make the request
      ref = push socket, "pftp.server.disable", %{}

      # Wait for the response, which is empty (but :ok)
      assert_reply ref, :ok, response, timeout()
      assert response.data == %{}

      # My PFTP server is now disabled
      assert %PublicFTP{is_active: false} = PublicFTPQuery.fetch_server(server)
    end
  end

  describe "pftp.file.add" do
    test "adds a file" do
      {socket, %{gateway: server}} = ChannelSetup.join_server(own_server: true)
      {file, _} = SoftwareSetup.file(server_id: server.server_id)
      SoftwareSetup.PFTP.pftp(server_id: server.server_id)

      params = %{"file_id": to_string(file.file_id)}

      ref = push socket, "pftp.file.add", params

      assert_reply ref, :ok, response, timeout()
      assert response.data == %{}

      [entry] = PublicFTPQuery.list_files(server)
      assert entry == file
    end
  end

  describe "pftp.file.remove" do
    test "removes a file" do
      {socket, %{gateway: server}} = ChannelSetup.join_server(own_server: true)
      SoftwareSetup.PFTP.pftp(server_id: server.server_id)
      {_, %{file: file}} = SoftwareSetup.PFTP.file(server_id: server.server_id)

      # The file exists
      assert PublicFTPQuery.fetch_file(file)

      params = %{"file_id" => to_string(file.file_id)}

      ref = push socket, "pftp.file.remove", params

      assert_reply ref, :ok, response, timeout()
      assert response.data == %{}

      # Now it doesn't
      refute PublicFTPQuery.fetch_file(file)
    end
  end

  describe "pftp.file.download" do
    test "starts the download of a PFTP file" do
      {socket, %{gateway: server}} = ChannelSetup.join_server(own_server: true)
      {pftp, _} = SoftwareSetup.PFTP.pftp(real_server: true)
      {_, %{file: file}} = SoftwareSetup.PFTP.file(server_id: pftp.server_id)

      {:ok, [nip]} = CacheQuery.from_server_get_nips(pftp.server_id)

      params = %{
        "file_id" => to_string(file.file_id),
        "ip" => nip.ip,
        "network_id" => to_string(nip.network_id)
      }

      ref = push socket, "pftp.file.download", params

      assert_reply ref, :ok, %{}, timeout(:slow)

      assert_push "event", _top_recalcado_event, timeout()
      assert_push "event", process_created_event, timeout()

      assert process_created_event.data.target_file.id == to_string(file.file_id)
      assert process_created_event.data.type == "file_download"
      assert process_created_event.data.data.connection_type == "public_ftp"
      assert process_created_event.data.network_id == to_string(@internet_id)

      assert Enum.empty?(process_created_event.data.access.file)

      TOPHelper.top_stop(server)
    end
  end
end
