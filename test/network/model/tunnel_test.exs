defmodule Helix.Network.Model.TunnelTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel

  @moduletag :unit

  describe "create/4" do
    test "works without a bounce list" do
      net = %Network{}
      gateway = Random.pk()
      destination = Random.pk()
      bounces = []

      changeset = Tunnel.create(net, gateway, destination, bounces)

      assert changeset.valid?
    end

    test "works with bounce list" do
      net = %Network{}
      gateway = Random.pk()
      destination = Random.pk()
      bounces = [Random.pk(), Random.pk(), Random.pk()]

      changeset = Tunnel.create(net, gateway, destination, bounces)

      assert changeset.valid?
    end

    test "fails if node is repeated" do
      net = %Network{}
      gateway = Random.pk()
      destination = Random.pk()
      repeated = Random.pk()
      bounces = [Random.pk(), repeated, Random.pk(), repeated]

      changeset = Tunnel.create(net, gateway, destination, bounces)

      refute changeset.valid?
    end

    test "fails if gateway and destination are the same" do
      net = %Network{}
      gateway = Random.pk()
      destination = gateway
      bounces = [Random.pk(), Random.pk()]

      changeset = Tunnel.create(net, gateway, destination, bounces)

      refute changeset.valid?
    end

    test "fails if gateway or destination are on bounce list" do
      net = %Network{}
      gateway = Random.pk()
      destination = Random.pk()
      bounces = [gateway, destination]

      changeset = Tunnel.create(net, gateway, destination, bounces)

      refute changeset.valid?
    end

    test "prepares link list" do
      net = %Network{}
      gateway = Random.pk()
      destination = Random.pk()
      bounces = []

      changeset = Tunnel.create(net, gateway, destination, bounces)
      links = Ecto.Changeset.get_change(changeset, :links)

      # gateway -> destination
      assert 1 == Enum.count(links)
    end

    test "includes bounce nodes on link list" do
      net = %Network{}
      gateway = Random.pk()
      destination = Random.pk()
      bounces = [Random.pk(), Random.pk(), Random.pk()]

      changeset = Tunnel.create(net, gateway, destination, bounces)
      links = Ecto.Changeset.get_change(changeset, :links)

      # gateway -> bounce1;
      # bounce1 -> bounce2;
      # bounce2 -> bounce3;
      # bounce3 -> destination
      assert 4 == Enum.count(links)
    end

    test "generated links are valid" do
      net = %Network{}
      gateway = Random.pk()
      destination = Random.pk()
      bounces = [Random.pk(), Random.pk(), Random.pk()]

      changeset = Tunnel.create(net, gateway, destination, bounces)
      links = Ecto.Changeset.get_change(changeset, :links)

      Enum.all?(links, fn changeset -> assert changeset.valid? end)
    end

    test "all nodes from the tunnel are included as links" do
      net = %Network{}
      gateway = Random.pk()
      destination = Random.pk()
      bounces = [Random.pk(), Random.pk(), Random.pk()]

      changeset = Tunnel.create(net, gateway, destination, bounces)
      links = Ecto.Changeset.get_change(changeset, :links)

      expected_nodes = MapSet.new(bounces ++ [gateway, destination])
      nodes = Enum.reduce(links, MapSet.new(), fn changeset, acc ->
        acc
        |> MapSet.put(Ecto.Changeset.get_field(changeset, :source_id))
        |> MapSet.put(Ecto.Changeset.get_field(changeset, :destination_id))
      end)

      assert MapSet.equal?(expected_nodes, nodes)
    end

    test "nodes used on tunnel are ordered" do
      net = %Network{}
      gateway = Random.pk()
      destination = Random.pk()
      bounces = [Random.pk(), Random.pk(), Random.pk(), Random.pk()]

      changeset = Tunnel.create(net, gateway, destination, bounces)
      struct = Ecto.Changeset.apply_changes(changeset)
      links = struct.links

      links = Enum.map(links, &({&1.source_id, &1.sequence}))
      expected = Enum.with_index([gateway| bounces])

      assert :maps.from_list(expected) == :maps.from_list(links)
    end
  end
end
