defmodule Helix.Server.Websocket.Channel.Server.Requests.CrackerTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup
  alias Helix.Test.Server.Setup, as: ServerSetup

  describe "cracker.bruteforce" do
    test "bruteforce attack is started" do
      {socket, %{gateway: gateway}} =
        ChannelSetup.join_server([own_server: true])

      {target, _} = ServerSetup.server()

      {:ok, [target_nip]} =
        CacheQuery.from_server_get_nips(target.server_id)

      {_cracker, _} =
        SoftwareSetup.file([type: :cracker, server_id: gateway.server_id])

      params = %{
        network_id: to_string(target_nip.network_id),
        ip: target_nip.ip,
        bounces: []
      }

      # Submit request
      ref = push socket, "cracker.bruteforce", params

      # Wait for response
      assert_reply ref, :ok, response, timeout(:slow)

      # All required fields are there
      assert response.data.type == "cracker_bruteforce"
      assert response.data.file
      assert response.data.access.origin_id
      assert response.data.access.priority
      assert response.data.access.usage
      assert response.data.network_id
      assert response.data.state
      assert response.data.progress
      assert response.data.target_ip

      # It definitely worked. Yay!
      assert ProcessQuery.fetch(response.data.process_id)
      assert TunnelQuery.fetch_connection(response.data.access.connection_id)

      TOPHelper.top_stop(gateway)
    end

    test "attempt to crack without a cracker" do
      {socket, %{gateway: _}} =
        ChannelSetup.join_server([own_server: true])

      {target, _} = ServerSetup.server()

      {:ok, [target_nip]} =
        CacheQuery.from_server_get_nips(target.server_id)

      params = %{
        network_id: to_string(target_nip.network_id),
        ip: target_nip.ip,
        bounces: []
      }

      # Submit request
      ref = push socket, "cracker.bruteforce", params
      assert_reply ref, :error, response, timeout(:fast)

      assert response.data.message == "cracker_not_found"
    end
  end
end
