defmodule Helix.Network.Action.TunnelTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Model.Connection.ConnectionClosedEvent
  alias Helix.Network.Query.Tunnel, as: TunnelQuery

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup

  defp closed_event(conn) do
    %ConnectionClosedEvent{
      connection_id: conn.connection_id,
      tunnel_id: conn.tunnel_id,
      network_id: NetworkHelper.internet_id(),
      reason: :normal
    }
  end

  describe "close_connections_where/4 without filter" do
    test "with 1 match, no filter" do
      {tunnel, %{gateway: gateway_id, destination: destination_id}} =
        NetworkSetup.tunnel([fake_servers: true])

      # Creates two connections, but only one will match since we'll search for
      # connections of type :ssh
      {ssh, _} =
        NetworkSetup.connection([tunnel_id: tunnel.tunnel_id, type: :ssh])
      {ftp, _} =
        NetworkSetup.connection([tunnel_id: tunnel.tunnel_id, type: :ftp])

      # Make sure the connections are there
      assert [ftp, ssh] ==
        TunnelQuery.connections_on_tunnels_between(gateway_id, destination_id)

      # Conditionally close connections of type :ssh
      assert [event] =
        TunnelAction.close_connections_where(gateway_id, destination_id, :ssh)

      # The SSH connection was removed, the FTP one wasn't
      assert [ftp] ==
        TunnelQuery.connections_on_tunnels_between(gateway_id, destination_id)

      # Returned the correct event
      assert event == closed_event(ssh)
    end

    test "with multiple matches, no filter" do
      {tunnel, %{gateway: gateway_id, destination: destination_id}} =
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

      # Make sure the connections are there
      assert [login1, wire1, ftp2, ftp1, ssh3, ssh2, ssh1] ==
        TunnelQuery.connections_on_tunnels_between(gateway_id, destination_id)

      # Conditionally close connections of type :ssh
      assert events =
        TunnelAction.close_connections_where(gateway_id, destination_id, :ssh)

      # Only the SSH connections were removed
      assert [login1, wire1, ftp2, ftp1] ==
        TunnelQuery.connections_on_tunnels_between(gateway_id, destination_id)

      # Make sure it returned the correct events
      assert events ==
        [closed_event(ssh3), closed_event(ssh2), closed_event(ssh1)]
    end

    test "with 1 match; with filter" do
      {tunnel, %{gateway: gateway_id, destination: destination_id}} =
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

      # Make sure the connections are there
      assert [ftp_ok1, ssh_ok2, ssh_ok1, ssh_expired] ==
        TunnelQuery.connections_on_tunnels_between(gateway_id, destination_id)

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
          destination_id,
          :ssh,
          filter)

      # The SSH connection was removed, the FTP one wasn't
      assert [ftp_ok1, ssh_ok2, ssh_ok1] ==
        TunnelQuery.connections_on_tunnels_between(gateway_id, destination_id)

      assert event == closed_event(ssh_expired)
    end

    test "with multiple matches; with filter" do
      {tunnel, %{gateway: gateway_id, destination: destination_id}} =
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

      # Make sure the connections are there
      assert [ftp_ok1, ssh_ok2, ssh_ok1, ssh_expired2, ssh_expired1] ==
        TunnelQuery.connections_on_tunnels_between(gateway_id, destination_id)

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
          destination_id,
          :ssh,
          filter)

      # The SSH connection was removed, the FTP one wasn't
      assert [ftp_ok1, ssh_ok2, ssh_ok1] ==
        TunnelQuery.connections_on_tunnels_between(gateway_id, destination_id)

      # Make sure the return events are correct
      assert events == [closed_event(ssh_expired2), closed_event(ssh_expired1)]
    end

    test "with no matches but existing connections" do
      {tunnel, %{gateway: gateway_id, destination: destination_id}} =
        NetworkSetup.tunnel([fake_servers: true])

      {ssh1, _} =
        NetworkSetup.connection([tunnel_id: tunnel.tunnel_id, type: :ssh])

      # Removing :ftp connections, but there are none!
      assert [] ==
        TunnelAction.close_connections_where(gateway_id, destination_id, :ftp)

      # As expected, the SSH connection is still there
      assert [ssh1] ==
        TunnelQuery.connections_on_tunnels_between(gateway_id, destination_id)
    end

    test "without any connections on the tunnel" do
      {_tunnel, %{gateway: gateway_id, destination: destination_id}} =
        NetworkSetup.tunnel([fake_servers: true])

      TunnelAction.close_connections_where(gateway_id, destination_id, :ftp)

      assert [] ==
        TunnelQuery.connections_on_tunnels_between(gateway_id, destination_id)
    end

    test "without a tunnel" do
      {gateway, _} = ServerSetup.fake_server()
      {destination, _} = ServerSetup.fake_server()

      gateway_id = gateway.server_id
      destination_id = destination.server_id

      # Ensures nothing blew up
      assert [] ==
        TunnelAction.close_connections_where(gateway_id, destination_id, :ftp)
    end
  end
end
