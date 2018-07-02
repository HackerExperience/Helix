defmodule Helix.Server.Public.IndexTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Public.Index, as: ServerIndex

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  describe "index/1" do
    test "indexes player server correctly" do
      {server, %{entity: entity}} = ServerSetup.server()

      index = ServerIndex.index(entity)

      # Player has two initial servers (Campaign and Freeplay)
      assert length(index.player) == 2
      assert Enum.empty?(index.remote)

      desktop = Enum.find(index.player, &(&1.server == server))
      desktop_story =
        Enum.find(index.player, &(&1.server.type == :desktop_story))

      assert desktop
      assert desktop_story
      refute Enum.empty?(desktop.nips)
      assert Enum.empty?(desktop.endpoints)
      refute Map.has_key?(desktop, :bounces)
    end

    test "indexes remote connections (endpoints)" do
      {player, %{entity: entity}} = ServerSetup.server()

      {target1, _} = ServerSetup.server()
      {target2, _} = ServerSetup.server()

      target1_nip = ServerHelper.get_nip(target1)
      target2_nip = ServerHelper.get_nip(target2)

      tunnel1_opts =
        [gateway_id: player.server_id, target_id: target1.server_id]
      NetworkSetup.connection([tunnel_opts: tunnel1_opts, type: :ssh])

      {tunnel2_bounce, _} = NetworkSetup.Bounce.bounce()
      tunnel2_opts =
        [
          gateway_id: player.server_id,
          target_id: target2.server_id,
          bounce_id: tunnel2_bounce.bounce_id
        ]
      NetworkSetup.connection([tunnel_opts: tunnel2_opts, type: :ssh])

      index = ServerIndex.index(entity)

      result_gateway = Enum.find(index.player, &(&1.server == player))

      assert find_endpoint(result_gateway.endpoints, target1_nip)
      assert find_endpoint(result_gateway.endpoints, target2_nip)

      endpoint_target1 = find_endpoint(index.remote, target1_nip)
      endpoint_target2 = find_endpoint(index.remote, target2_nip)

      refute endpoint_target1.bounce_id
      assert endpoint_target2.bounce_id == tunnel2_bounce.bounce_id

      assert endpoint_target1.password == target1.password
      assert endpoint_target2.password == target2.password

      assert endpoint_target1.network_id
      assert endpoint_target1.ip
    end

    @tag :slow
    test "removes duplicates" do
      {gateway1, %{entity: entity}} = ServerSetup.server()
      {gateway2, _} = ServerSetup.server([entity_id: entity.entity_id])

      {target1, _} = ServerSetup.server()
      {target2, _} = ServerSetup.server()

      target1_nip = ServerHelper.get_nip(target1)
      target2_nip = ServerHelper.get_nip(target2)

      # Gateway1 is connected to Target1 and Target2
      g1t1_opts =
        [gateway_id: gateway1.server_id, target_id: target1.server_id]
      NetworkSetup.connection([tunnel_opts: g1t1_opts, type: :ssh])

      g1t2_opts =
        [gateway_id: gateway1.server_id, target_id: target2.server_id]
      NetworkSetup.connection([tunnel_opts: g1t2_opts, type: :ssh])

      # Gateway2 is connected to Target1 and Target2
      g2t1_opts =
        [gateway_id: gateway2.server_id, target_id: target1.server_id]
      NetworkSetup.connection([tunnel_opts: g2t1_opts, type: :ssh])

      g2t2_opts =
        [gateway_id: gateway2.server_id, target_id: target2.server_id]
      NetworkSetup.connection([tunnel_opts: g2t2_opts, type: :ssh])

      index = ServerIndex.index(entity)

      # 3 player servers (2 gateways + 1 storyline), 2 remote servers
      assert length(index.player) == 3
      assert length(index.remote) == 2

      result_gateway1 = Enum.find(index.player, &(&1.server == gateway1))
      result_gateway2 = Enum.find(index.player, &(&1.server == gateway2))

      gateway1_endpoints =
        Enum.sort(
          [%{network_id: target1_nip.network_id, ip: target1_nip.ip},
           %{network_id: target2_nip.network_id, ip: target2_nip.ip}])
      # In this context, gateway2 endpoints are the same as gateway1
      gateway2_endpoints = gateway1_endpoints

      # Endpoints are listed correctly
      assert Enum.sort(result_gateway1.endpoints) == gateway1_endpoints
      assert Enum.sort(result_gateway2.endpoints) == gateway2_endpoints
    end
  end

  describe "render_index/1" do
    test "rendered output is json friendly" do
      {player, %{entity: entity}} = ServerSetup.server()

      {target, _} = ServerSetup.server()
      target_nip = ServerHelper.get_nip(target)

      tunnel_bounce = [ServerSetup.id()]
      tunnel_opts =
        [gateway_id: player.server_id,
         target_id: target.server_id,
         bounces: tunnel_bounce]
      NetworkSetup.connection([tunnel_opts: tunnel_opts, type: :ssh])

      index = ServerIndex.index(entity)
      rendered = ServerIndex.render_index(index)

      rendered_gateway =
        Enum.find(
          rendered.player,
          &(&1.server_id == to_string(player.server_id))
        )

      rendered_endpoint =
        Enum.find(
          rendered.remote,
          &(
            &1.network_id == to_string(target_nip.network_id) and
            &1.ip == target_nip.ip
          )
        )

      # IDs are binary
      assert is_binary(rendered_gateway.server_id)
      assert is_binary(rendered_endpoint.network_id)

      # Endpoints are binary
      assert Enum.each(rendered_gateway.endpoints, fn nip ->
        assert is_binary(nip.network_id)
        assert is_binary(nip.ip)
      end)

      # Nips are binary
      Enum.each(rendered_gateway.nips, fn nip ->
        assert is_binary(nip.network_id)
        assert is_binary(nip.ip)
      end)
    end
  end

  describe "gateway/2" do
    test "returns the gateway server" do
      {server, %{entity: entity}} = ServerSetup.server()
      server_nips = ServerHelper.get_all_nips(server)

      gateway = ServerIndex.gateway(server, entity.entity_id)

      # ServerIndex info
      assert gateway.nips == server_nips
      assert gateway.name == server.hostname
      assert gateway.password == server.password
      assert gateway.type == server.type

      # Info retrieved from sub-Indexes
      assert gateway.main_storage
      assert gateway.storages
      assert gateway.hardware
      assert gateway.logs
      assert gateway.processes
      assert gateway.tunnels
      assert gateway.notifications
    end
  end

  describe "render_gateway/1" do
    test "renders the gateway index" do
      {server, %{entity: entity}} = ServerSetup.server()

      rendered =
        server
        |> ServerIndex.gateway(entity.entity_id)
        |> ServerIndex.render_gateway()

      assert is_binary(rendered.name)
      assert is_binary(rendered.password)
      assert is_binary(rendered.server_type)

      Enum.each(rendered.nips, fn [network_id, ip] ->
        assert is_binary(network_id)
        assert is_binary(ip)
      end)

      assert rendered.main_storage
      assert rendered.storages
      assert rendered.hardware
      assert rendered.logs
      assert rendered.processes
      assert rendered.tunnels
      assert rendered.notifications
    end
  end

  describe "remote/2" do
    test "returns the remote server" do
      {server, _} = ServerSetup.server()
      {entity, _} = EntitySetup.entity()
      server_nips = ServerHelper.get_all_nips(server)

      remote = ServerIndex.remote(server, entity.entity_id)

      # ServerIndex info
      assert remote.nips == server_nips

      # Info specific to gateway
      refute Map.has_key?(remote, :password)
      refute Map.has_key?(remote, :name)

      # Info retrieved from sub-Indexes
      assert remote.main_storage
      assert remote.storages
      assert remote.hardware
      assert remote.logs
      assert remote.processes
      assert remote.tunnels
      assert remote.notifications
    end
  end

  describe "render_remote/1" do
    test "renders the remote index" do
      {server, _} = ServerSetup.server()
      {entity, _} = EntitySetup.entity()

      rendered =
        server
        |> ServerIndex.remote(entity.entity_id)
        |> ServerIndex.render_remote()

      Enum.each(rendered.nips, fn [network_id, ip] ->
        assert is_binary(network_id)
        assert is_binary(ip)
      end)

      assert rendered.main_storage
      assert rendered.storages
      assert rendered.hardware
      assert rendered.logs
      assert rendered.processes
      assert rendered.tunnels
      assert rendered.notifications
    end
  end

  defp find_endpoint(endpoints, %{network_id: network_id, ip: ip}),
    do: Enum.find(endpoints, &(&1.network_id == network_id and &1.ip == ip))
end
