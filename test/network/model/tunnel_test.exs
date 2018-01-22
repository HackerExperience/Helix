defmodule Helix.Network.Model.TunnelTest do

  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias Helix.Network.Model.Tunnel

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup

  @moduletag :unit

  @internet_id NetworkHelper.internet_id()

  defp create_params(network_id, gateway_id, destination_id, bounce_id \\ nil) do
    %{
      network_id: network_id,
      gateway_id: gateway_id,
      destination_id: destination_id,
      bounce_id: bounce_id
    }
  end

  describe "create/4" do
    test "without bounce" do
      gateway_id = ServerSetup.id()
      destination_id = ServerSetup.id()

      changeset =
        @internet_id
        |> create_params(gateway_id, destination_id)
        |> Tunnel.create()

      assert changeset.valid?

      tunnel = Changeset.apply_changes(changeset)
      refute tunnel.bounce_id

      # There are no hops and no :bounce assoc
      assert Enum.empty?(tunnel.hops)
      refute Ecto.assoc_loaded?(tunnel.bounce)
    end

    test "with bounce" do
      gateway_id = ServerSetup.id()
      destination_id = ServerSetup.id()
      {bounce, _} = NetworkSetup.Bounce.bounce()

      changeset =
        @internet_id
        |> create_params(gateway_id, destination_id)
        |> Tunnel.create(bounce)

      assert changeset.valid?

      tunnel = Changeset.apply_changes(changeset)
      assert tunnel.bounce_id == bounce.bounce_id

      # It holds information about the hops and the :bounce assoc
      assert tunnel.hops == bounce.links
      assert tunnel.bounce == bounce
    end

    # TODO: Bounce responsibility
    # test "fails if node is repeated" do
    #   net = NetworkQuery.internet()
    #   gateway = ServerSetup.id()
    #   destination = ServerSetup.id()
    #   repeated = ServerSetup.id()
    #   bounces = [
    #     ServerSetup.id(),
    #     repeated,
    #     ServerSetup.id(),
    #     ServerSetup.id(),
    #     repeated
    #   ]

    #   changeset = Tunnel.create(net, gateway, destination, bounces)

    #   refute changeset.valid?
    # end

    test "fails if gateway and destination are the same" do
      gateway_id = ServerSetup.id()
      destination_id = gateway_id

      changeset =
        @internet_id
        |> create_params(gateway_id, destination_id)
        |> Tunnel.create()

      refute changeset.valid?
      assert :destination_id in Keyword.keys(changeset.errors)
    end

    test "fails if gateway or destination are on bounce list" do
      gateway_id = ServerSetup.id()
      target_id = ServerSetup.id()

      {bounce_with_gateway, _} =
        NetworkSetup.Bounce.fake_bounce(
          links: [
            {ServerSetup.id(), @internet_id, NetworkHelper.ip()},
            {gateway_id, @internet_id, NetworkHelper.ip()},
            {ServerSetup.id(), @internet_id, NetworkHelper.ip()}
          ]
        )
      {bounce_with_target, _} =
        NetworkSetup.Bounce.fake_bounce(
          links: [
            {ServerSetup.id(), @internet_id, NetworkHelper.ip()},
            {target_id, @internet_id, NetworkHelper.ip()},
            {ServerSetup.id(), @internet_id, NetworkHelper.ip()}
          ]
        )

      changeset1 =
        @internet_id
        |> create_params(gateway_id, target_id)
        |> Tunnel.create(bounce_with_gateway)

      refute changeset1.valid?
      assert :hops in Keyword.keys(changeset1.errors)

      changeset2 =
        @internet_id
        |> create_params(gateway_id, target_id)
        |> Tunnel.create(bounce_with_target)

      refute changeset2.valid?
      assert :hops in Keyword.keys(changeset2.errors)
    end
  end
end
