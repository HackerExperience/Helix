defmodule Helix.Server.State.Websocket.ChannelTest do

  use ExUnit.Case, async: true

  import HELL.MacroHelpers

  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Server.State.Websocket.Channel, as: ServerWebsocketChannelState

  alias HELL.TestHelper.Random
  alias Helix.Test.Server.State.Helper, as: ServerStateHelper

  defp generate_join do
    entity_id = Entity.ID.generate()
    server_id = Server.ID.generate()
    network_id = Network.ID.generate()
    ip = Random.ipv4()

    {entity_id, server_id, {network_id, ip}}
  end

  defp join(sequence: total) do
    {entity_id, server_id, nip} = generate_join()

    0..(total - 1)
    |> Enum.each(fn i ->
      ServerWebsocketChannelState.join(entity_id, server_id, nip, i)
    end)

    {entity_id, server_id, nip}
  end
  defp join do
    {entity_id, server_id, nip} = generate_join()

    ServerWebsocketChannelState.join(entity_id, server_id, nip, 0)

    {entity_id, server_id, nip, 0}
  end

  defp lookup_server(server_id),
    do: ServerStateHelper.lookup_server(server_id) |> cast_server()

  defp lookup_entity(entity_id),
    do: ServerStateHelper.lookup_entity(entity_id) |> cast_entity()

  defp cast_server(server),
    do: ServerStateHelper.cast_server_entry(server)

  defp cast_entity(entity),
    do: ServerStateHelper.cast_entity_entry(entity)

  docp """
  Given a server entry, find its channels based on nip and counter
  """
  defp find_channels(server, nip = {_, _}) do
    server.channels
    |> Enum.filter(&({&1.network_id, &1.ip} == nip))
    |> Enum.sort()
  end

  docp """
  Given an entity entry, find its servers based on server_id, nip and counter
  """
  defp find_servers(entity, nip = {_, _}, counter) do
    entity.servers
    |> Enum.filter(&({&1.network_id, &1.ip} == nip and &1.counter == counter))
    |> Enum.sort()
  end
  defp find_servers(entity, server_id, counter) do
    entity.servers
    |> Enum.filter(&(&1.server_id == server_id and &1.counter == counter))
    |> Enum.sort()
  end
  defp find_servers(entity, nip = {_, _}) do
    entity.servers
    |> Enum.filter(&({&1.network_id, &1.ip} == nip))
    |> Enum.sort()
  end
  defp find_servers(entity, server_id),
    do: Enum.filter(entity.servers, &(&1.server_id == server_id)) |> Enum.sort()

  describe "join/4" do
    test "entity and servers entries are created" do
      {entity_id, server_id, nip} = generate_join()

      ServerWebsocketChannelState.join(entity_id, server_id, nip, 0)

      server_entry = lookup_server(server_id)
      assert server_entry.server_id == server_id

      [channel] = find_channels(server_entry, nip)
      assert channel.counter == 0
      assert {channel.network_id, channel.ip} == nip

      entity_entry = lookup_entity(entity_id)
      assert entity_entry.entity_id == entity_id

      [server] = find_servers(entity_entry, server_id)
      assert server.server_id == server_id
      assert server.counter == 0
      assert {server.network_id, server.ip} == nip
    end

    test "entity joining the same server multiple times" do
      {entity_id, server_id, nip = {network_id, ip}} = generate_join()

      ServerWebsocketChannelState.join(entity_id, server_id, nip, 0)
      ServerWebsocketChannelState.join(entity_id, server_id, nip, 1)
      ServerWebsocketChannelState.join(entity_id, server_id, nip, 2)

      server_entry = lookup_server(server_id)
      assert server_entry.server_id == server_id

      channels = [c1, c2, c3] = find_channels(server_entry, nip)

      assert c1.counter == 0
      assert c2.counter == 1
      assert c3.counter == 2

      assert Enum.all?(channels, &(&1.ip == ip))
      assert Enum.all?(channels, &(&1.network_id == network_id))

      entity_entry = lookup_entity(entity_id)
      assert entity_entry.entity_id == entity_id

      servers = [s1, s2, s3] = find_servers(entity_entry, server_id)
      assert s1.counter == 0
      assert s2.counter == 1
      assert s3.counter == 2

      assert Enum.all?(servers, &(&1.network_id == network_id))
      assert Enum.all?(servers, &(&1.ip == ip))
    end

    test "multiple entities joining the same server" do
      {e1_id, server_id, nip} = generate_join()
      {e2_id, _, _} = generate_join()

      ServerWebsocketChannelState.join(e1_id, server_id, nip, 0)
      ServerWebsocketChannelState.join(e2_id, server_id, nip, 0)

      # Only one channel is created
      server_entry = lookup_server(server_id)
      assert [_channel] = find_channels(server_entry, nip)

      # One entry to `e1`
      e1_entry = lookup_entity(e1_id)
      assert [_server] = find_servers(e1_entry, server_id)

      # One entry to `e2`
      e2_entry = lookup_entity(e2_id)
      assert [_server] = find_servers(e2_entry, server_id)
    end
  end

  describe "leave/4" do
    test "removes entity entry from database*" do
      {entity_id, server_id, nip, counter} = join()

      assert lookup_server(server_id)
      assert lookup_entity(entity_id)

      ServerWebsocketChannelState.leave(entity_id, server_id, nip, counter)

      refute lookup_entity(entity_id)

      # Server is still there, because it's remove asynchronously. See `gc/0`
      assert lookup_server(server_id)
    end

    test "removing one entry won't affect others" do
      {entity_id, server_id, nip} = join(sequence: 2)

      assert lookup_server(server_id)
      assert lookup_entity(entity_id)

      ServerWebsocketChannelState.leave(entity_id, server_id, nip, 1)

      # Removed the one with counter `1`, counter `0` is still there
      entry_entity = lookup_entity(entity_id)
      assert [_server] = find_servers(entry_entity, nip, 0)
      assert [] == find_servers(entry_entity, nip, 1)
    end

    test "removing greater counter first" do
      {entity_id, server_id, nip} = join(sequence: 2)

      assert lookup_server(server_id)
      assert lookup_entity(entity_id)

      ServerWebsocketChannelState.leave(entity_id, server_id, nip, 0)

      entry_entity = lookup_entity(entity_id)
      assert [_server] = find_servers(entry_entity, nip, 1)
      assert [] == find_servers(entry_entity, nip, 0)
    end
  end

  describe "gc/0" do
    test "removes unused servers" do
      # Scenario: `e1` is connected twice to `s1`. `e2` is connected once to
      # `s2`, and once to `s1`
      {e1_id, s1_id, s1_nip} = join(sequence: 2)
      {e2_id, s2_id, s2_nip, _} = join()

      ServerWebsocketChannelState.join(e2_id, s1_id, s1_nip, 0)

      # Save the entries before running `gc/0` for the first time
      entry_s1_before = lookup_server(s1_id)
      entry_s2_before = lookup_server(s2_id)

      # Run garbage collector. Nothing should happen, as the entities are still
      # active on the servers
      ServerWebsocketChannelState.gc()

      # Nothing changed
      assert lookup_server(s1_id) == entry_s1_before
      assert lookup_server(s2_id) == entry_s2_before

      # `e2` leaves `s2`. Now no one is connected to `s2`
      ServerWebsocketChannelState.leave(e2_id, s2_id, s2_nip, 0)

      # `s2` is still there, since garbage collector hasn't run yet
      assert lookup_server(s2_id) == entry_s2_before

      # Run gc
      ServerWebsocketChannelState.gc()

      # Bad bad `s2` server no donut for you
      refute lookup_server(s2_id)

      # `e1` leaves `s1` once, so does `e2`
      ServerWebsocketChannelState.leave(e1_id, s1_id, s1_nip, 0)
      ServerWebsocketChannelState.leave(e2_id, s1_id, s1_nip, 0)

      # Run gc
      ServerWebsocketChannelState.gc()

      # `s1` still exists because of `e1` connection with counter 0
      entry_s1 = lookup_server(s1_id)

      # Notice something interesting: `s1` still lists as it had two channels,
      # when right now only one of them is being used (e1_id with counter 1),
      # so `gc` could have deleted channel with counter 0 completely.
      # That's not done currently for, uh, "simplification purposes".
      # A server entry is only gc'd if literally no one is joined to it.
      assert length(entry_s1.channels) == 2

      # Finally, remove the last connection to it
      ServerWebsocketChannelState.leave(e1_id, s1_id, s1_nip, 1)

      # Run gc
      ServerWebsocketChannelState.gc()

      # It's gone
      refute lookup_server(s1_id)
    end
  end

  describe "invalidate_server/2" do
    test "removes server and entity entries" do
      # Scenario: One server with two players logged into it. One extra server
      # joined by `e2` which should remain unaffected
      {e1_id, s1_id, s1_nip, _} = join()
      {e2_id, s2_id, _, _} = join()
      ServerWebsocketChannelState.join(e2_id, s1_id, s1_nip, 0)

      # Everything is fa-aine
      assert lookup_server(s1_id)
      assert lookup_server(s2_id)
      assert lookup_entity(e1_id)
      assert lookup_entity(e2_id)

      # Force invalidation of `s1_id`
      ServerWebsocketChannelState.invalidate_server(s1_id, s1_nip)

      # `s1` no longer exists. `e1` is gone too, since `s1` was the only server
      # it was logged into.
      refute lookup_server(s1_id)
      refute lookup_entity(e1_id)

      # `e2` and `s2` still exist because they are in use.
      assert lookup_server(s2_id)
      assert lookup_entity(e2_id)
    end
  end

  describe "list_open_channels/1" do
    test "multiple entities, one channel" do
      {_, server_id, nip = {network_id, ip}, _} = join()
      ServerWebsocketChannelState.join("e2", server_id, nip, 0)
      ServerWebsocketChannelState.join("e3", server_id, nip, 0)
      ServerWebsocketChannelState.join("e4", server_id, nip, 0)

      assert [channel] =
        ServerWebsocketChannelState.list_open_channels(server_id)
      assert channel.counter == 0
      assert channel.network_id == to_string(network_id)
      assert channel.ip == ip
    end

    test "multiple channels" do
      {_, server_id, nip} = join(sequence: 4)
      ServerWebsocketChannelState.join("e2", server_id, nip, 0)
      ServerWebsocketChannelState.join("e3", server_id, nip, 0)
      ServerWebsocketChannelState.join("e4", server_id, nip, 0)

      channels = ServerWebsocketChannelState.list_open_channels(server_id)
      assert length(channels) == 4
    end

    test "unlisted server" do
      server_id = Server.ID.generate()
      refute ServerWebsocketChannelState.list_open_channels(server_id)
    end
  end

  describe "get_next_counter/3" do
    test "first server being joined" do
      next = ServerWebsocketChannelState.get_next_counter("e", "s", {"n", "ip"})
      assert next == 0
    end

    test "different nip on same server" do
      {entity_id, server_id, _, 0} = join()

      next =
        ServerWebsocketChannelState.get_next_counter(
          entity_id,
          server_id,
          {"n", "ip"}
        )

      assert next == 0
    end

    test "second server being joined (ordered)" do
      {entity_id, server_id, nip, 0} = join()

      next =
        ServerWebsocketChannelState.get_next_counter(entity_id, server_id, nip)
      assert next == 1

      # De novo, de novo
      ServerWebsocketChannelState.join(entity_id, server_id, nip, next)

      next =
        ServerWebsocketChannelState.get_next_counter(entity_id, server_id, nip)
      assert next == 2
    end

    test "next counter with gap" do
      # Scenario: We'll create a sequence (counters 0 and 1), and them leave
      # from counter 0 while keeping counter 1 active. The next login should
      # use counter 0
      {entity_id, server_id, nip} = join(sequence: 2)

      # Leave counter 0
      ServerWebsocketChannelState.leave(entity_id, server_id, nip, 0)

      next =
        ServerWebsocketChannelState.get_next_counter(entity_id, server_id, nip)
      assert next == 0
    end
  end
end
