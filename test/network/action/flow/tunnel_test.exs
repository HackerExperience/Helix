defmodule Helix.Network.Action.Flow.TunnelTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Action.Flow.Tunnel, as: TunnelFlow

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup

  @internet_id NetworkHelper.internet_id()

  @relay nil

  describe "connect/3" do
    test "creates the connection" do
      {gen_tunnel, _} = NetworkSetup.tunnel()

      {type, meta} = {:ssh, %{}}

      assert {:ok, tunnel, connection} =
        TunnelFlow.connect(gen_tunnel, {type, meta}, @relay)

      assert tunnel == gen_tunnel
      assert connection.tunnel_id == gen_tunnel.tunnel_id
      assert connection.connection_type == type
      assert connection.meta == meta
    end
  end

  describe "connect/6" do
    test "creates the connection (and tunnel if needed)" do
      {bounce, _} = NetworkSetup.Bounce.bounce()

      {%{server_id: gateway_id}, _} = ServerSetup.server()
      {%{server_id: target_id}, _} = ServerSetup.server()

      {type, meta} = {:ssh, %{}}

      assert {:ok, tunnel, connection} =
        TunnelFlow.connect(
          @internet_id, gateway_id, target_id, bounce, {type, meta}, @relay
        )

      # Tunnel created correctly
      assert tunnel.gateway_id == gateway_id
      assert tunnel.target_id == target_id
      assert tunnel.bounce_id == bounce.bounce_id

      # Connection was created as well
      assert connection.tunnel_id == tunnel.tunnel_id
      assert connection.connection_type == type
      assert connection.meta == meta

      # Let's try again. A new connection should be created
      assert {:ok, tunnel2, connection2} =
        TunnelFlow.connect(
          @internet_id, gateway_id, target_id, bounce, {type, meta}, @relay
        )

      # It's the same tunnel as before
      assert tunnel2 == tunnel

      # But it's a different connection
      refute connection2 == connection
      assert connection2.tunnel_id == tunnel.tunnel_id
      assert connection2.connection_type == type
      assert connection2.meta == meta
    end
  end

  describe "connect_once/6" do
    test "creates the connection once" do
      {bounce, _} = NetworkSetup.Bounce.bounce()

      {%{server_id: gateway_id}, _} = ServerSetup.server()
      {%{server_id: target_id}, _} = ServerSetup.server()

      {type, meta} = {:ssh, %{}}

      # Creates for the first time with {type, meta}
      assert {:ok, tunnel, connection} =
        TunnelFlow.connect_once(
          @internet_id, gateway_id, target_id, bounce, {type, meta}, @relay
        )

      # Tunnel created correctly
      assert tunnel.gateway_id == gateway_id
      assert tunnel.target_id == target_id
      assert tunnel.bounce_id == bounce.bounce_id

      # Connection was created as well
      assert connection.tunnel_id == tunnel.tunnel_id
      assert connection.connection_type == type
      assert connection.meta == meta

      # Let's run it again. The *same* tunnel and connection should be returned
      assert {:ok, tunnel, connection} ==  # Notice the `==`
        TunnelFlow.connect_once(
          @internet_id, gateway_id, target_id, bounce, {type, meta}, @relay
        )

      # I'll run it again, but now with a different `type`
      assert {:ok, tunnel2, connection2} =
        TunnelFlow.connect_once(
          @internet_id, gateway_id, target_id, bounce, {:ftp, meta}, @relay
        )

      # The tunnel is the same
      assert tunnel2 == tunnel

      # But the connection isn't
      refute connection2 == connection
      assert connection2.connection_type == :ftp

      # I'll run it again, but now with a different `meta`
      assert {:ok, tunnel3, connection3} =
        TunnelFlow.connect_once(
          @internet_id, gateway_id, target_id, bounce, {type, %{h: :e2}}, @relay
        )

      # Tunnel is the same
      assert tunnel3 == tunnel

      # But the connection isn't
      refute connection3 == connection
      assert connection3.meta == %{h: :e2}

      # I'll run it again, same {type, meta} but without using a bounce
      assert {:ok, tunnel4, connection4} =
        TunnelFlow.connect_once(
          @internet_id, gateway_id, target_id, nil, {type, meta}, @relay
        )

      # `tunnel4` is a new tunnel, since no tunnel existed between `gateway` and
      # `target`, on `@internet`, with NO bounce.
      refute tunnel4 == tunnel
      assert tunnel4.gateway_id == gateway_id
      assert tunnel4.target_id == target_id
      refute tunnel4.bounce_id

      # As a result, `connection4` is also brand new, even though it has the
      # same info ({type, meta}) as `connection`.
      refute connection4 == connection
      assert connection4.tunnel_id == tunnel4.tunnel_id
      assert connection4.connection_type == type
      assert connection4.meta == meta
    end
  end
end
