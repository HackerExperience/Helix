defmodule Helix.Network.Action.TunnelTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Query.Tunnel, as: TunnelQuery

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Network.Setup, as: NetworkSetup

  describe "close_connections_where/4 without filter" do
    test "with 1 match, no filter" do
      {tunnel, %{gateway: gateway_id, target: target_id}} =
        NetworkSetup.tunnel([fake_servers: true])

      # Creates two connections, but only one will match since we'll search for
      # connections of type :ssh
      {ssh, _} =
        NetworkSetup.connection([tunnel_id: tunnel.tunnel_id, type: :ssh])
      {ftp, _} =
        NetworkSetup.connection([tunnel_id: tunnel.tunnel_id, type: :ftp])

      connections =
        gateway_id
        |> TunnelQuery.connections_on_tunnels_between(target_id)
        |> Enum.sort()

      # Make sure the connections are there
      assert Enum.sort([ftp, ssh]) == connections

      # Conditionally close connections of type :ssh
      assert [event] =
        TunnelAction.close_connections_where(gateway_id, target_id, :ssh)

      # The SSH connection was removed, the FTP one wasn't
      assert [ftp] ==
        TunnelQuery.connections_on_tunnels_between(gateway_id, target_id)

      # Returned the correct event
      assert event == EventSetup.Network.connection_closed(ssh)
    end

    test "with multiple matches, no filter" do
      {tunnel, %{gateway: gateway_id, target: target_id}} =
        NetworkSetup.tunnel([fake_servers: true])

      tunnel_id = tunnel.tunnel_id

      # Creates several connections, from which three will match (type == :ssh)
      {ssh1, _} =
        NetworkSetup.connection([tunnel_id: tunnel_id, type: :ssh])
      {ssh2, _} =
        NetworkSetup.connection([tunnel_id: tunnel_id, type: :ssh])
      {ssh3, _} =
        NetworkSetup.connection([tunnel_id: tunnel_id, type: :ssh])
      {ftp1, _} =
        NetworkSetup.connection([tunnel_id: tunnel_id, type: :ftp])
      {ftp2, _} =
        NetworkSetup.connection([tunnel_id: tunnel_id, type: :ftp])
      {wire1, _} =
        NetworkSetup.connection([tunnel_id: tunnel_id, type: :wire_transfer])
      {login1, _} =
        NetworkSetup.connection([tunnel_id: tunnel_id, type: :bank_login])

      connections =
        gateway_id
        |> TunnelQuery.connections_on_tunnels_between(target_id)
        |> Enum.sort()

      # Make sure the connections are there
      assert Enum.sort([login1, wire1, ftp2, ftp1, ssh3, ssh2, ssh1]) ==
        connections

      # Conditionally close connections of type :ssh
      assert events =
        TunnelAction.close_connections_where(gateway_id, target_id, :ssh)

      connections =
        gateway_id
        |> TunnelQuery.connections_on_tunnels_between(target_id)
        |> Enum.sort()

      # Only the SSH connections were removed
      assert Enum.sort([login1, wire1, ftp2, ftp1]) == connections

      # Make sure it returned the correct events
      assert Enum.sort(events) ==
        [EventSetup.Network.connection_closed(ssh3),
         EventSetup.Network.connection_closed(ssh2),
         EventSetup.Network.connection_closed(ssh1)] |> Enum.sort()
    end

    test "with 1 match; with filter" do
      {tunnel, %{gateway: gateway_id, target: target_id}} =
        NetworkSetup.tunnel([fake_servers: true])
      tunnel_id = tunnel.tunnel_id

      # Creates 4 connections, of which only one will match our params.
      # From the 4 created connections, 3 are SSH ones, with only one having the
      # metadata `expired == true`. The fourth connection is an FTP one that
      # does have the `expired == true` condition, but it's not an SSH one.
      {ssh_expired, _} =
        NetworkSetup.connection(
          [tunnel_id: tunnel_id, type: :ssh, meta: %{"expired" => true}])
      {ssh_ok1, _} =
        NetworkSetup.connection(
          [tunnel_id: tunnel_id, type: :ssh, meta: %{"expired" => false}])
      {ssh_ok2, _} =
        NetworkSetup.connection(
          [tunnel_id: tunnel_id, type: :ssh, meta: nil])
      {ftp_ok1, _} =
        NetworkSetup.connection(
          [tunnel_id: tunnel_id, type: :ftp, meta: %{"expired" => true}])

      connections =
        gateway_id
        |> TunnelQuery.connections_on_tunnels_between(target_id)
        |> Enum.sort()

      # Make sure the connections are there
      assert Enum.sort([ftp_ok1, ssh_ok2, ssh_ok1, ssh_expired]) == connections

      # From the resulting set, filter (for deletion) connections where
      # `expired == true`
      filter = fn meta ->
        meta
        && meta["expired"] == true
      end

      # Conditionally close connections of type :ssh and `expired == true`
      assert [event] =
        TunnelAction.close_connections_where(
          gateway_id,
          target_id,
          :ssh,
          filter)

      connections =
        gateway_id
        |> TunnelQuery.connections_on_tunnels_between(target_id)
        |> Enum.sort()

      # The SSH connection was removed, the FTP one wasn't
      assert Enum.sort([ftp_ok1, ssh_ok2, ssh_ok1]) == connections

      assert event == EventSetup.Network.connection_closed(ssh_expired)
    end

    test "with multiple matches; with filter" do
      {tunnel, %{gateway: gateway_id, target: target_id}} =
        NetworkSetup.tunnel([fake_servers: true])
      tunnel_id = tunnel.tunnel_id

      # Creates 5 connections, of which only TWO will match our params.
      # From the 5 created connections, 4 are SSH ones, with two having the
      # metadata `expired == true`. The fifth connection is an FTP one that
      # does have the `expired == true` condition, but it's not an SSH one.
      {ssh_expired1, _} =
        NetworkSetup.connection(
          [tunnel_id: tunnel_id, type: :ssh, meta: %{"expired" => true}])
      {ssh_expired2, _} =
        NetworkSetup.connection(
          [tunnel_id: tunnel_id, type: :ssh, meta: %{"expired" => true}])
      {ssh_ok1, _} =
        NetworkSetup.connection(
          [tunnel_id: tunnel_id, type: :ssh, meta: %{"expired" => false}])
      {ssh_ok2, _} =
        NetworkSetup.connection(
          [tunnel_id: tunnel_id, type: :ssh, meta: nil])
      {ftp_ok1, _} =
        NetworkSetup.connection(
          [tunnel_id: tunnel_id, type: :ftp, meta: %{"expired" => true}])

      connections =
        gateway_id
        |> TunnelQuery.connections_on_tunnels_between(target_id)
        |> Enum.sort()

      # Make sure the connections are there
      assert connections ==
        Enum.sort([ftp_ok1, ssh_ok2, ssh_ok1, ssh_expired2, ssh_expired1])

      # From the resulting set, filter (for deletion) connections where
      # `expired == true`
      filter = fn meta ->
        meta
        && meta["expired"] == true
      end

      # Conditionally close connections of type :ssh and `expired == true`
      assert events =
        TunnelAction.close_connections_where(
          gateway_id,
          target_id,
          :ssh,
          filter)

      connections =
        gateway_id
        |> TunnelQuery.connections_on_tunnels_between(target_id)
        |> Enum.sort()

      # The SSH connection was removed, the FTP one wasn't
      assert Enum.sort([ftp_ok1, ssh_ok2, ssh_ok1]) == connections

      # Make sure the return events are correct
      assert Enum.sort(events) ==
        [EventSetup.Network.connection_closed(ssh_expired2),
         EventSetup.Network.connection_closed(ssh_expired1)] |> Enum.sort()
    end

    test "with no matches but existing connections" do
      {tunnel, %{gateway: gateway_id, target: target_id}} =
        NetworkSetup.tunnel([fake_servers: true])

      {ssh1, _} =
        NetworkSetup.connection([tunnel_id: tunnel.tunnel_id, type: :ssh])

      # Removing :ftp connections, but there are none!
      assert [] ==
        TunnelAction.close_connections_where(gateway_id, target_id, :ftp)

      # As expected, the SSH connection is still there
      assert [ssh1] ==
        TunnelQuery.connections_on_tunnels_between(gateway_id, target_id)
    end

    test "without any connections on the tunnel" do
      {_tunnel, %{gateway: gateway_id, target: target_id}} =
        NetworkSetup.tunnel([fake_servers: true])

      TunnelAction.close_connections_where(gateway_id, target_id, :ftp)

      assert [] ==
        TunnelQuery.connections_on_tunnels_between(gateway_id, target_id)
    end

    test "without a tunnel" do
      {gateway, _} = ServerSetup.fake_server()
      {target, _} = ServerSetup.fake_server()

      gateway_id = gateway.server_id
      target_id = target.server_id

      # Ensures nothing blew up
      assert [] ==
        TunnelAction.close_connections_where(gateway_id, target_id, :ftp)
    end
  end
end
