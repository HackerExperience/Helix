defmodule Helix.Server.Websocket.Channel.Server.Requests.BruteforceTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup
  alias Helix.Test.Server.Setup, as: ServerSetup

  describe "bruteforce" do
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
      ref = push socket, "bruteforce", params

      # Wait for response
      assert_reply ref, :ok, response

      # All required fields are there
      assert response.data.process_id
      assert response.data.file_id
      assert response.data.connection_id
      assert response.data.network_id
      assert response.data.source_ip
      assert response.data.target_ip
      assert response.data.type == "cracker_bruteforce"

      # It definitely worked. Yay!
      assert ProcessQuery.fetch(response.data.process_id)
      assert TunnelQuery.fetch_connection(response.data.connection_id)

      TOPHelper.top_stop(gateway.server_id)
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
      ref = push socket, "bruteforce", params

      # Wait for response
      assert_reply ref, :error, response

      assert response.data.message == "cracker_not_found"
    end
  end
end
