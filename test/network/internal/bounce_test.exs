defmodule Helix.Network.Internal.BounceTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Internal.Bounce, as: BounceInternal

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup

  @internet_id NetworkHelper.internet_id()

  describe "fetch/1" do
    test "returns the bounce, formatted" do
      {gen_bounce, _} = NetworkSetup.Bounce.bounce()

      bounce = BounceInternal.fetch(gen_bounce.bounce_id)

      assert bounce.bounce_id == gen_bounce.bounce_id
      assert bounce.name == gen_bounce.name
      assert bounce.entity_id == gen_bounce.entity_id
      assert bounce.links == gen_bounce.links
    end

    test "returns empty if bounce is not found" do
      refute BounceInternal.fetch(NetworkHelper.Bounce.id())
    end
  end

  describe "get_entries_on_server/1" do
    test "returns all bounces that are going through server" do
      # `bounce1` and `bounce2` share a common link (`b1e1`)
      {bounce1, %{entries: [b1e1, b1e2 | _]}} = NetworkSetup.Bounce.bounce()
      {bounce2, _} =
        NetworkSetup.Bounce.bounce(
          links: [{b1e1.server_id, b1e1.network_id, b1e1.ip}]
        )

      # There are two ongoing bounces on server `b1e1.server_id`
      assert [entry1, entry2] =
        BounceInternal.get_entries_on_server(b1e1.server_id)

      # See? Same link on different bounces
      assert entry1.bounce_id == bounce1.bounce_id
      assert entry2.bounce_id == bounce2.bounce_id

      assert entry1.server_id == entry2.server_id
      assert entry1.network_id == entry2.network_id
      assert entry1.ip == entry2.ip

      # But there's only one bounce going through `b1e2.server_id`
      assert [entry3] = BounceInternal.get_entries_on_server(b1e2.server_id)
      assert entry3.bounce_id == bounce1.bounce_id
    end

    test "returns empty list if nothing is found" do
      assert Enum.empty?(BounceInternal.get_entries_on_server(ServerSetup.id()))
    end
  end

  describe "get_entries_on_nip/1" do
    test "returns all bounces that are going through the nip" do
      # `bounce1` and `bounce2` share a common link (`b1e1`)
      {bounce1, %{entries: [b1e1, b1e2 | _]}} = NetworkSetup.Bounce.bounce()
      {bounce2, _} =
        NetworkSetup.Bounce.bounce(
          links: [{b1e1.server_id, b1e1.network_id, b1e1.ip}]
        )

      # There are two ongoing bounces on nip `{b1e1.network_id, b1e1.ip}`
      assert [entry1, entry2] =
        BounceInternal.get_entries_on_nip(b1e1.network_id, b1e1.ip)

      # See? Same link on different bounces (Enum.find used to ignore order)
      refute entry1.bounce_id == entry2.bounce_id
      assert Enum.find([entry1, entry2], &(&1.bounce_id == bounce1.bounce_id))
      assert Enum.find([entry1, entry2], &(&1.bounce_id == bounce2.bounce_id))

      assert entry1.server_id == entry2.server_id
      assert entry1.network_id == entry2.network_id
      assert entry1.ip == entry2.ip

      # But there's only one bounce going through `{b1e2.network_id, b1e2.ip}`
      assert [entry3] =
        BounceInternal.get_entries_on_nip(b1e2.network_id, b1e2.ip)
      assert entry3.bounce_id == bounce1.bounce_id
    end

    test "returns empty list if nothing is found" do
      assert Enum.empty?(BounceInternal.get_entries_on_server(ServerSetup.id()))
    end
  end

  describe "fetch_from_connection/1" do
    test "finds the bounce linked to the connection" do
      {bounce, _} = NetworkSetup.Bounce.bounce()
      {tunnel, _} = NetworkSetup.tunnel(bounce_id: bounce.bounce_id)
      {connection, _} = NetworkSetup.connection(tunnel_id: tunnel.tunnel_id)

      # Returned the bounce
      assert bounce ==
        BounceInternal.fetch_from_connection(connection.connection_id)
    end

    test "returns empty when connection has no bounce" do
      refute BounceInternal.fetch_from_connection(NetworkHelper.connection_id())
    end
  end

  describe "create/3" do
    test "creates the Bounce and related structures" do
      entity_id = EntitySetup.id()
      name = NetworkHelper.Bounce.name()

      link1_server_id = ServerSetup.id()
      link1_network_id = @internet_id
      link1_ip = NetworkHelper.ip()
      link1 = {link1_server_id, link1_network_id, link1_ip}

      link2_server_id = ServerSetup.id()
      link2_network_id = @internet_id
      link2_ip = NetworkHelper.ip()
      link2 = {link2_server_id, link2_network_id, link2_ip}

      links = [link1, link2]

      assert {:ok, bounce} = BounceInternal.create(entity_id, name, links)

      # Created the bounce as expected
      assert bounce.bounce_id
      assert bounce.entity_id == entity_id
      assert bounce.name == name
      assert bounce.links == links

      # Created entries for both links
      assert [entry1] = BounceInternal.get_entries_on_server(link1_server_id)
      assert entry1.bounce_id == bounce.bounce_id
      assert entry1.server_id == link1_server_id
      assert entry1.network_id == link1_network_id
      assert entry1.ip == link1_ip

      assert [entry2] =
        BounceInternal.get_entries_on_nip(link2_network_id, link2_ip)
      assert entry2.bounce_id == bounce.bounce_id
      assert entry2.server_id == link2_server_id
      assert entry2.network_id == link2_network_id
      assert entry2.ip == link2_ip
    end
  end

  describe "update/3" do
    test "performs a noop when no change was made" do
      {bounce, _} = NetworkSetup.Bounce.bounce()
      assert {:ok, bounce} ==
        BounceInternal.update(bounce, name: bounce.name, links: bounce.links)
    end

    test "append one link" do
      # Initial bounce has 2 entries
      {bounce, _} = NetworkSetup.Bounce.bounce(total: 2)

      assert length(bounce.links) == 2

      link_server_id = ServerSetup.id()
      {%{network_id: link_network_id}, _} = NetworkSetup.network()
      link_ip = NetworkHelper.ip()
      link = {link_server_id, link_network_id, link_ip}

      # New links = previous links + `link` at the last position
      new_links = bounce.links ++ [link]

      assert {:ok, new_bounce} = BounceInternal.update(bounce, links: new_links)

      # New bounce has 3 entries!
      assert new_bounce.bounce_id == bounce.bounce_id
      assert new_bounce.links == new_links
    end

    test "remove last link" do
      {bounce, _} = NetworkSetup.Bounce.bounce(total: 2)

      # New links = previous links - last one
      new_links = Enum.drop(bounce.links, -1)

      assert {:ok, new_bounce} = BounceInternal.update(bounce, links: new_links)
      assert new_bounce.bounce_id == bounce.bounce_id
      assert new_bounce.links == new_links
    end

    test "shake, rattle and roll" do
      # Scenario:
      # Bounce1: [A, B, C]
      # Bounce2: [C, A, D, E]
      # Bounce3: [F]

      generate_link = fn ->
        {ServerSetup.id(), @internet_id, NetworkHelper.ip()}
      end

      a = generate_link.()
      b = generate_link.()
      c = generate_link.()
      d = generate_link.()
      e = generate_link.()
      f = generate_link.()

      {bounce1, _} = NetworkSetup.Bounce.bounce(links: [a, b, c])
      assert bounce1.links == [a, b, c]

      assert {:ok, bounce2} =
        BounceInternal.update(bounce1, links: [c, a, d, e])
      assert bounce2.links == [c, a, d, e]
      assert bounce2 == BounceInternal.fetch(bounce1.bounce_id)

      assert {:ok, bounce3} = BounceInternal.update(bounce2, links: [f])
      assert bounce3.links == [f]
      assert bounce3 == BounceInternal.fetch(bounce1.bounce_id)
    end

    test "rename" do
      {bounce, _} = NetworkSetup.Bounce.bounce(total: 2)

      new_name = NetworkHelper.Bounce.name()

      assert {:ok, new_bounce} = BounceInternal.update(bounce, name: new_name)

      assert new_bounce.name == new_name
    end

    test "rename and change links at the same time" do
      {bounce, _} = NetworkSetup.Bounce.bounce(total: 2)

      # Reverse (swap positions)
      new_links = Enum.reverse(bounce.links)
      refute new_links == bounce.links

      new_name = NetworkHelper.Bounce.name()

      assert {:ok, new_bounce} =
        BounceInternal.update(bounce, name: new_name, links: new_links)
      assert new_bounce.bounce_id == bounce.bounce_id
      assert new_bounce.links == new_links
      assert new_bounce.name == new_name
    end
  end
end
