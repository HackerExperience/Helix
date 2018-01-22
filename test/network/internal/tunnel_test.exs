defmodule Helix.Network.Internal.TunnelTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Macros

  alias Helix.Server.Model.Server
  alias Helix.Network.Internal.Tunnel, as: TunnelInternal

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup

  @internet NetworkHelper.internet()
  @internet_id @internet.network_id

  describe "fetch/1" do
    test "returns the tunnel, formatted (with bounce)" do
      {bounce, _} = NetworkSetup.Bounce.bounce(total: 2)
      {t, _} = NetworkSetup.tunnel(bounce_id: bounce.bounce_id)

      tunnel = TunnelInternal.fetch(t)

      assert tunnel == t
      assert tunnel.bounce == %{bounce| sorted: nil}
      assert tunnel.hops == bounce.links
    end

    test "returns the tunnel, formatted (no bounce)" do
      {t, _} = NetworkSetup.tunnel()

      tunnel = TunnelInternal.fetch(t)

      assert_map tunnel, t, skip: :bounce
      refute tunnel.bounce
    end

    test "returns empty when no tunnel is found" do
      refute TunnelInternal.fetch(NetworkSetup.tunnel_id())
    end
  end

  describe "get_hops/1" do
    test "returns all hops between tunnel with bounce" do
      {bounce, _} = NetworkSetup.Bounce.bounce(total: 2)
      {tunnel, _} = NetworkSetup.tunnel(bounce_id: bounce.bounce_id)

      # Created tunnel includes the bounce data (testing NetworkSetup)
      assert tunnel.bounce_id == bounce.bounce_id
      assert tunnel.bounce == %{bounce| sorted: nil}
      assert tunnel.hops == bounce.links

      assert bounce.links == TunnelInternal.get_hops(tunnel)
    end

    test "returns empty list on tunnel without bounce" do
      {tunnel, _} = NetworkSetup.tunnel()
      refute tunnel.bounce_id

      assert Enum.empty?(TunnelInternal.get_hops(tunnel))
    end
  end

  describe "get_tunnel/4" do
    test "returns the tunnel (with bounce)" do
      {bounce, _} = NetworkSetup.Bounce.bounce(total: 2)
      {tunnel, _} = NetworkSetup.tunnel(bounce_id: bounce.bounce_id)

      assert tunnel ==
        TunnelInternal.get_tunnel(
          tunnel.gateway_id,
          tunnel.destination_id,
          tunnel.network_id,
          tunnel.bounce_id
        )
    end
  end

  describe "create/4" do
    test "creates tunnel and underlying links" do
      gateway_id = ServerSetup.id()
      target_id = ServerSetup.id()
      {bounce, _} = NetworkSetup.Bounce.bounce(total: 2)

      assert {:ok, tunnel} =
        TunnelInternal.create(@internet, gateway_id, target_id, bounce)

      assert tunnel.gateway_id == gateway_id
      assert tunnel.destination_id == target_id
      assert tunnel.network_id == @internet_id
      assert tunnel.hops == bounce.links

      assert [l1, l2, l3] = TunnelInternal.get_links(tunnel)

      [{hop1_id, _, _}, {hop2_id, _, _}] = bounce.links

      # Links are a link-ed list :)
      assert l1.source_id == gateway_id
      assert l1.target_id == hop1_id
      assert l2.source_id == l1.target_id
      assert l2.target_id == hop2_id
      assert l3.source_id == l2.target_id
      assert l3.target_id == target_id

      # Sequence is fine too
      assert l1.sequence == 0
      assert l2.sequence == 1
      assert l3.sequence == 2
    end

    test "creates tunnel without a bounce" do
      gateway_id = ServerSetup.id()
      target_id = ServerSetup.id()

      assert {:ok, tunnel} =
        TunnelInternal.create(@internet, gateway_id, target_id, nil)

      assert tunnel.gateway_id == gateway_id
      assert tunnel.destination_id == target_id
      assert tunnel.network_id == @internet_id
      assert Enum.empty?(tunnel.hops)
      refute tunnel.bounce
      refute tunnel.bounce_id

      assert [l1] = TunnelInternal.get_links(tunnel)

      assert l1.tunnel_id == tunnel.tunnel_id
      assert l1.source_id == gateway_id
      assert l1.target_id == target_id
      assert l1.sequence == 0
    end
  end

  describe "tunnels_between/3" do
    test "returns all tunnels between two servers" do
      {tunnel1, _} = NetworkSetup.tunnel()
      {tunnel2, _} =
        NetworkSetup.tunnel(
          gateway_id: tunnel1.gateway_id, destination_id: tunnel1.destination_id
        )

      # Makes sure NetworkSetup worked as expected
      assert tunnel1.gateway_id == tunnel2.gateway_id
      assert tunnel1.destination_id == tunnel2.destination_id

      # Tunnels 3 and 4 only meet the condition partially
      {_tunnel3, _} = NetworkSetup.tunnel(gateway_id: tunnel1.gateway_id)
      {_tunnel4, _} = NetworkSetup.tunnel(destination_id: tunnel1.destination_id)

      assert [t1, t2] =
        TunnelInternal.tunnels_between(tunnel1.gateway_id, tunnel1.destination_id)

      assert Enum.find([t1, t2], &(&1.tunnel_id == tunnel1.tunnel_id))
      assert Enum.find([t1, t2], &(&1.tunnel_id == tunnel2.tunnel_id))
    end

    test "returns empty (nil) when there's no tunnel between the servers" do
      assert Enum.empty?(
        TunnelInternal.tunnels_between(ServerSetup.id(), ServerSetup.id())
      )
    end

    test "may be filtered by network" do
      {network, _} = NetworkSetup.network()
      {bounce, _} = NetworkSetup.Bounce.bounce()

      {tunnel1, _} = NetworkSetup.tunnel(bounce_id: bounce.bounce_id)
      {tunnel2, _} =
        NetworkSetup.tunnel(
          gateway_id: tunnel1.gateway_id,
          destination_id: tunnel1.destination_id,
          network_id: network.network_id
        )

      assert [t2] =
        TunnelInternal.tunnels_between(
          tunnel1.gateway_id, tunnel1.destination_id, network.network_id
        )

      assert t2 == tunnel2
    end
  end

  describe "connections_through_node/1" do
    test "returns all connections that pass through node" do
      server_id = Server.ID.generate()
      opts = [fake_servers: true]

      {tunnel1, _} = NetworkSetup.tunnel([gateway_id: server_id] ++ opts)

      TunnelInternal.start_connection(tunnel1, :ssh)

      {tunnel2, _} = NetworkSetup.tunnel([destination_id: server_id] ++ opts)

      TunnelInternal.start_connection(tunnel2, :ssh)
      TunnelInternal.start_connection(tunnel2, :ftp)

      {bounce, _} =
        NetworkSetup.Bounce.bounce(
          servers: [
            ServerSetup.id(), server_id, ServerSetup.id(), ServerSetup.id()
          ]
        )
      {tunnel3, _} = NetworkSetup.tunnel([bounce_id: bounce.bounce_id] ++ opts)

      TunnelInternal.start_connection(tunnel3, :ssh)
      TunnelInternal.start_connection(tunnel3, :ftp)
      TunnelInternal.start_connection(tunnel3, :public_ftp)

      connections = TunnelInternal.connections_through_node(server_id)

      assert 6 == Enum.count(connections)
    end
  end

  describe "inbound_connections/1" do
    test "list the conections that are incident on node" do
      server_id = Server.ID.generate()

      {dummy_bounce, _} = NetworkSetup.Bounce.bounce(total: 2)

      {tunnel1, _} =
        NetworkSetup.tunnel(
          gateway_id: server_id,
          bounce_id: dummy_bounce.bounce_id,
          fake_servers: true
        )

      # This is not inbound since the connection *starts* from `server_id`
      TunnelInternal.start_connection(tunnel1, :ssh)

      assert Enum.empty?(TunnelInternal.inbound_connections(server_id))

      {tunnel2, _} =
        NetworkSetup.tunnel(
          destination_id: server_id,
          bounce_id: dummy_bounce.bounce_id,
          fake_servers: true
        )

      # Those are inbound because they start from a random server into the
      # bounce nodes and finally on the `server_id`
      {:ok, t2c1} = TunnelInternal.start_connection(tunnel2, :ssh)
      {:ok, t2c2} = TunnelInternal.start_connection(tunnel2, :ftp)

      assert Enum.sort([t2c1, t2c2]) ==
        Enum.sort(TunnelInternal.inbound_connections(server_id))

      {bounce_with_server, _} =
        NetworkSetup.Bounce.bounce(
          servers: [ServerSetup.id(), server_id, ServerSetup.id()]
        )

      {tunnel3, _} =
        NetworkSetup.tunnel(
          bounce_id: bounce_with_server.bounce_id, fake_servers: true
        )

      # Those are also inbound as they originate from a random server, onto the
      # bounces (which includes `server_id`) and then to some destination
      {:ok, t3c1} = TunnelInternal.start_connection(tunnel3, :ssh)
      {:ok, t3c2} = TunnelInternal.start_connection(tunnel3, :ftp)
      {:ok, t3c3} = TunnelInternal.start_connection(tunnel3, :ssh)

      assert Enum.sort([t2c1, t2c2, t3c1, t3c2, t3c3]) ==
        Enum.sort(TunnelInternal.inbound_connections(server_id))
    end
  end

  describe "outbound_connections/1" do
    test "list the conections that emanate from node" do
      server_id = Server.ID.generate()

      {dummy_bounce, _} = NetworkSetup.Bounce.bounce(total: 2)

      {tunnel1, _} =
        NetworkSetup.tunnel(
          gateway_id: server_id,
          bounce_id: dummy_bounce.bounce_id,
          fake_servers: true
        )

      # This emanates from `server_id` since it goes from the `server_id` to the
      # bounces and finally to the destination
      {:ok, t1c1} = TunnelInternal.start_connection(tunnel1, :ssh)

      assert [t1c1] == TunnelInternal.outbound_connections(server_id)

      {tunnel2, _} =
        NetworkSetup.tunnel(
          destination_id: server_id,
          bounce_id: dummy_bounce.bounce_id,
          fake_servers: true
        )

      # Those don't emanate from the server as the connection is incident on it
      TunnelInternal.start_connection(tunnel2, :ssh)
      TunnelInternal.start_connection(tunnel2, :wire_transfer)

      assert [t1c1] == TunnelInternal.outbound_connections(server_id)

      {bounce_with_server, _} =
        NetworkSetup.Bounce.bounce(
          servers: [ServerSetup.id(), server_id, ServerSetup.id()]
        )

      {tunnel3, _} =
        NetworkSetup.tunnel(
          bounce_id: bounce_with_server.bounce_id, fake_servers: true
        )

      # Those do emanate from `server_id` onto another bounce and finally on the
      # destination
      {:ok, t3c1} = TunnelInternal.start_connection(tunnel3, :ssh)
      {:ok, t3c2} = TunnelInternal.start_connection(tunnel3, :ftp)
      {:ok, t3c3} = TunnelInternal.start_connection(tunnel3, :ssh)

      assert Enum.sort([t1c1, t3c1, t3c2, t3c3]) ==
        Enum.sort(TunnelInternal.outbound_connections(server_id))
    end
  end

  describe "start_connection/2" do
    test "starts a new connection every call" do
      {tunnel, _} = NetworkSetup.tunnel(fake_servers: true)

      assert {:ok, c1} = TunnelInternal.start_connection(tunnel, :ssh)
      assert {:ok, c2} = TunnelInternal.start_connection(tunnel, :ftp)

      assert c1.connection_type == :ssh
      assert c2.connection_type == :ftp

      connections = TunnelInternal.get_connections(tunnel)
      assert 2 == Enum.count(connections)
    end
  end

  describe "close_connection/2" do
    test "deletes the connection" do
      {tunnel, _} = NetworkSetup.tunnel(fake_servers: true)

      {:ok, connection} = TunnelInternal.start_connection(tunnel, :ssh)

      TunnelInternal.close_connection(connection)

      refute TunnelInternal.fetch_connection(connection.connection_id)
    end
  end

  describe "get_links/1" do
    test "with a direct connection" do
      gateway_id = Server.ID.generate()
      destination_id = Server.ID.generate()

      {tunnel, _} =
        NetworkSetup.tunnel(
          gateway_id: gateway_id,
          destination_id: destination_id,
          fake_servers: true
        )

      assert [l1|l2] = TunnelInternal.get_links(tunnel)

      assert l1.source_id == gateway_id
      assert l1.target_id == destination_id
      assert Enum.empty?(l2)
    end

    test "with n=1 bounce" do
      gateway_id = Server.ID.generate()
      destination_id = Server.ID.generate()

      {bounce, _} = NetworkSetup.Bounce.bounce(total: 1)
      [{hop1_id, _, _}] = bounce.links

      {tunnel, _} =
        NetworkSetup.tunnel(
          gateway_id: gateway_id,
          destination_id: destination_id,
          bounce_id: bounce.bounce_id,
          fake_servers: true
        )

      assert [l1, l2] = TunnelInternal.get_links(tunnel)

      assert l1.source_id == gateway_id
      assert l1.target_id == hop1_id
      assert l2.source_id == hop1_id
      assert l2.target_id == destination_id
    end

    test "with n>1 bounce" do
      gateway_id = Server.ID.generate()
      target_id = Server.ID.generate()

      {bounce, _} = NetworkSetup.Bounce.bounce(total: 3)
      [{hop1_id, _, _}, {hop2_id, _, _}, {hop3_id, _, _}] = bounce.links

      {tunnel, _} =
        NetworkSetup.tunnel(
          gateway_id: gateway_id,
          destination_id: target_id,
          bounce_id: bounce.bounce_id,
          fake_servers: true
        )

      assert [l1, l2, l3, l4] = TunnelInternal.get_links(tunnel)

      assert l1.source_id == gateway_id
      assert l1.target_id == hop1_id
      assert l2.source_id == hop1_id
      assert l2.target_id == hop2_id
      assert l3.source_id == hop2_id
      assert l3.target_id == hop3_id
      assert l4.source_id == hop3_id
      assert l4.target_id == target_id
    end
  end

  describe "connections_originating_from/1" do
    test "lists connections correctly" do
      gateway_id = Server.ID.generate()

      # Tunnel1 has connections originating *from* `gateway`
      tunnel1_opts = [fake_servers: true, gateway_id: gateway_id]
      {tunnel1, _} = NetworkSetup.tunnel(tunnel1_opts)

      c1t1 = NetworkSetup.connection!([tunnel_id: tunnel1.tunnel_id])
      c2t1 = NetworkSetup.connection!([tunnel_id: tunnel1.tunnel_id])

      # Both c1t1 and c2t1 are indeed originating from `gateway_id`
      assert Enum.sort([c1t1, c2t1]) ==
        Enum.sort(TunnelInternal.connections_originating_from(gateway_id))

      # Tunnel2 has connections going *to* `gateway`
      tunnel2_opts = [fake_servers: true, destination_id: gateway_id]
      {tunnel2, _} = NetworkSetup.tunnel(tunnel2_opts)

      _c1t2 = NetworkSetup.connection!([tunnel_id: tunnel2.tunnel_id])
      _c2t2 = NetworkSetup.connection!([tunnel_id: tunnel2.tunnel_id])

      # As expected, nothing changed
      assert Enum.sort([c1t1, c2t1]) ==
        Enum.sort(TunnelInternal.connections_originating_from(gateway_id))

      # Tunnel2 has connections going *through* `gateway` (part of bounce)
      tunnel3_opts = [fake_servers: true, bounces: [gateway_id]]
      {tunnel3, _} = NetworkSetup.tunnel(tunnel3_opts)

      _c1t3 = NetworkSetup.connection!([tunnel_id: tunnel3.tunnel_id])
      _c2t3 = NetworkSetup.connection!([tunnel_id: tunnel3.tunnel_id])

      # Still only the first two connections
      assert Enum.sort([c1t1, c2t1]) ==
        Enum.sort(TunnelInternal.connections_originating_from(gateway_id))
    end
  end

  describe "connections_destined_to/1" do
    test "lists connections correctly" do
      server_id = Server.ID.generate()

      # Tunnel1 has connections originating *from* `server`
      tunnel1_opts = [fake_servers: true, gateway_id: server_id]
      {tunnel1, _} = NetworkSetup.tunnel(tunnel1_opts)

      _c1t1 = NetworkSetup.connection!([tunnel_id: tunnel1.tunnel_id])
      _c2t1 = NetworkSetup.connection!([tunnel_id: tunnel1.tunnel_id])

      # Tunnel2 has connections going *to* `server`
      tunnel2_opts = [fake_servers: true, destination_id: server_id]
      {tunnel2, _} = NetworkSetup.tunnel(tunnel2_opts)

      c1t2 = NetworkSetup.connection!([tunnel_id: tunnel2.tunnel_id])
      c2t2 = NetworkSetup.connection!([tunnel_id: tunnel2.tunnel_id])

      # Tunnel2 has connections going *through* `gateway` (part of bounce)
      tunnel3_opts = [fake_servers: true, bounces: [server_id]]
      {tunnel3, _} = NetworkSetup.tunnel(tunnel3_opts)

      _c1t3 = NetworkSetup.connection!([tunnel_id: tunnel3.tunnel_id])
      _c2t3 = NetworkSetup.connection!([tunnel_id: tunnel3.tunnel_id])

      # Get connections originating from `gateway`
      connections = TunnelInternal.connections_destined_to(server_id)

      assert length(connections) == 2
      assert Enum.sort(connections) == Enum.sort([c2t2, c1t2])
    end
  end

  describe "get_remote_endpoints/1" do
    test "returns expected data" do
      gateway1 = Server.ID.generate()
      gateway2 = Server.ID.generate()

      target1 = Server.ID.generate()
      target2 = Server.ID.generate()
      target3 = Server.ID.generate()

      bounce1 = Server.ID.generate()
      bounce2 = Server.ID.generate()

      {g2_bounce, _} = NetworkSetup.Bounce.bounce(servers: [bounce1, bounce2])

      gateway1_opts = [fake_servers: true, gateway_id: gateway1]
      gateway2_opts =
        [
          fake_servers: true,
          gateway_id: gateway2,
          bounce_id: g2_bounce.bounce_id
        ]

      {tun_g1t1, _} =
        NetworkSetup.tunnel(gateway1_opts ++ [destination_id: target1])
      {tun_g1t2, _} =
        NetworkSetup.tunnel(gateway1_opts ++ [destination_id: target2])
      {tun_g2t1, _} =
        NetworkSetup.tunnel(gateway2_opts ++ [destination_id: target1])
      {tun_g2t3, _} =
        NetworkSetup.tunnel(gateway2_opts ++ [destination_id: target3])

      # g1<>t1 has SSH connection
      NetworkSetup.connection([tunnel_id: tun_g1t1.tunnel_id, type: :ssh])

      # g1<>t2 has SSH connection
      NetworkSetup.connection([tunnel_id: tun_g1t2.tunnel_id, type: :ssh])
      NetworkSetup.connection([tunnel_id: tun_g1t2.tunnel_id, type: :ftp])

      # g2<>t1 does not have SSH connection
      NetworkSetup.connection([tunnel_id: tun_g2t1.tunnel_id, type: :ftp])

      # g2<>t3 has SSH connection
      NetworkSetup.connection([tunnel_id: tun_g2t3.tunnel_id, type: :ssh])

      result = TunnelInternal.get_remote_endpoints([gateway1, gateway2])

      assert Enum.sort(result[gateway1]) == Enum.sort([tun_g1t1, tun_g1t2])
      assert_map List.first(result[gateway2]), tun_g2t3, skip: [:bounce, :hops]
    end
  end
end
