defmodule Helix.Server.State.Websocket.Channel do
  @moduledoc """
  # Overview

  ServerWebsocketChannelState holds information about server channels in use by
  players. It's basically a giant in-memory mapping of server IDs to server NIPs
  {network_id, ip}.

  Its most important use case is event notification, when we want to notify all
  players logged into that one server that an event has occurred. Since the
  server channel identifier is its NIP, and a server may have multiple NIPs,
  it may be the case that the event should be broadcasted to multiple channels
  which are different in name but represent the same server.

  Another important case is our future goal of never leaking the internal server
  ID to the client. This can only be achieved if we identify servers through
  their NIPs, in which case the same server may have different channels, as
  explained above.

  Note that this state is only used on *remote* joins. Local joins are performed
  using the gateway's server ID, and as such this mapping is unnecessary.

  # Implementation & API

  The state is maintained on two ETS table, the `server` and `entity` one. The
  `server` table maps the server ID to the corresponding NIP, and the `entity`
  one maps an entity to the list of servers it is currently connected to.

  Joining a server remotely should notify the `join/4` function, which will sync
  the new entity, server and nips to the state.

  Leaving a server should notify the `leave/3` function, which will update the
  `entity` table, making sure that given entity is no longer marked as logged.

  Notice that it may be the case that this entity was the last one logged into
  the server, and thus the server has no one else connected to it. However,
  we keep the server on the `server` ETS table, since it's quite expensive to
  verify all the time whether there's someone logged in.

  Every hour or so, we run the `gc/0` method, which will garbage-collect the
  `server` ETS table, removing servers that are not in use by anyone.

  Notice that this module uses only strings internally, so it uses the `fmt/1`
  method to convert Helix-formatted data (IDs) to string.
  """

  use GenServer

  import HELL.Macros

  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server

  @type counter :: non_neg_integer

  @typep server_table_name :: :ets_server_websocket_channel_server
  @typep entity_table_name :: :ets_server_websocket_channel_entity

  @typep server_table :: [server_entry]
  @typep entity_table :: [entity_entry]

  @typep server_entry ::
    {server_id :: String.t, [server_entry_data]}

  @typep server_entry_data ::
    {nip, counter}

  @typep entity_entry ::
    {entity_id :: String.t, [entity_entry_data]}

  @typep entity_entry_data ::
    {server_id :: String.t, nip, counter}

  @typep nip :: {network_id :: String.t, ip :: String.t}

  @typep formatted_channel_data ::
    %{
      ip: String.t,
      network_id: Network.id,
      counter: counter
    }

  @registry_name :server_websocket_channel
  @ets_table_server :ets_server_websocket_channel_server
  @ets_table_entity :ets_server_websocket_channel_entity

  def start_link do
    {:ok, pid} = GenServer.start_link(__MODULE__, [], name: @registry_name)
    GenServer.call(@registry_name, :setup)
    {:ok, pid}
  end

  @doc """
  Persists the information that `entity_id` just joined `server_id` using the
  following `nip` and `counter`. Most of the times counter is 0.
  """
  @spec join(Entity.id, Server.id, {Network.id, IPv4.t}, counter) ::
    {:ok, term}
  def join(entity_id, server_id, {network_id, ip}, counter) do
    [entity_id, server_id, network_id] = fmt([entity_id, server_id, network_id])
    nip = {network_id, ip}

    GenServer.call(@registry_name, {:join, entity_id, server_id, nip, counter})
  end

  @doc """
  Persists the information that `entity_id` just logged out of `server_id`.

  Notice that, as explained on the moduledoc, it may be the case that this
  entity was the last one connected to the server. However, we do not perform
  such verification here, as it's expensive. If the server is no longer in use,
  it will remain temporarily on the `server` ETS table until this module's
  garbage collector (`gc/0`) is ran, which should happen automatically and as a
  background task.
  """
  @spec leave(Entity.id, Server.id, {Network.id, IPv4.t}, counter) ::
    {:ok, term}
  def leave(entity_id, server_id, {network_id, ip}, counter) do
    [entity_id, server_id, network_id] = fmt([entity_id, server_id, network_id])
    nip = {network_id, ip}

    GenServer.call(@registry_name, {:leave, entity_id, server_id, nip, counter})
  end

  @doc """
  Interface to the garbage collector method, which will remove from the `server`
  ETS table any server that is no longer connected by anyone.
  """
  def gc,
    do: GenServer.call(@registry_name, :gc)

  @doc """
  `invalidate_server/2` is useful when a given NIP is no longer valid (the
  server IP has changed). It will scan the `server` ETS table and remove the
  reference to the no-longer-valid NIP. Notice that, when this happens, the
  method responsible for resetting the server IP should have already kicked out
  all players connected to that specific server.
  """
  @spec invalidate_server(Server.id, {Network.id, IPv4.t}) ::
    {:ok, term}
  def invalidate_server(server_id, {network_id, ip}) do
    [server_id, network_id] = fmt([server_id, network_id])
    nip = {network_id, ip}

    GenServer.call(@registry_name, {:invalidate_server, server_id, nip})
  end

  @spec list_open_channels(Server.id) ::
    [formatted_channel_data]
    | nil
  @doc """
  Lists all open channels on the given `server_id`.
  """
  def list_open_channels(server_id) do
    server_id = fmt(server_id)

    GenServer.call(@registry_name, {:list_open_channels, server_id})
  end

  @spec get_next_counter(Entity.id, Server.id, {Network.id, IPv4.t}) ::
    counter
  @doc """
  Figures out the next counter for the `entity` on the `server` with the `nip`.
  """
  def get_next_counter(entity_id, server_id, {network_id, ip}) do
    [entity_id, server_id, network_id] = fmt([entity_id, server_id, network_id])
    nip = {network_id, ip}

    GenServer.call(@registry_name, {:next_counter, entity_id, server_id, nip})
  end

  @spec valid_counter?(Entity.id, Server.id, {Network.id, IPv4.t}, counter) ::
    boolean
  @doc """
  Checks whether the given counter is the next one
  """
  def valid_counter?(entity_id, server_id, nip, counter),
    do: get_next_counter(entity_id, server_id, nip) == counter

  @spec fmt([struct] | struct) ::
    [String.t] | String.t
  defp fmt(values) when is_list(values),
    do: Enum.map(values, &(to_string(&1)))
  defp fmt(value),
    do: to_string(value)

  # Callbacks

  def init(_),
    do: {:ok, []}

  @spec handle_call(:setup, term, term) ::
    {:reply, :ok, term}
  def handle_call(:setup, _from, state) do
    :ets.new(@ets_table_server, [:set, :protected, :named_table])
    :ets.new(@ets_table_entity, [:set, :protected, :named_table])
    {:reply, :ok, state}
  end

  @spec handle_call({:join, String.t, String.t, nip, counter}, term, term) ::
    {:reply, :ok, term}
  def handle_call({:join, entity_id, server_id, nip, counter}, _, state) do
    entry_server = get_entry_server(server_id)
    entry_entity = get_entry_entity(entity_id)

    {new_server, new_entity} =
      join_server(entry_server, entry_entity, {server_id, nip, counter})

    # Replaces the new entries, but only if it has changed.
    unless new_server == entry_server do
      :ets.insert(@ets_table_server, {server_id, new_server})
    end
    unless new_entity == entry_entity do
      :ets.insert(@ets_table_entity, {entity_id, new_entity})
    end

    {:reply, :ok, state}
  end

  @spec handle_call({:leave, String.t, String.t, nip, counter}, term, term) ::
    {:reply, :ok, term}
  def handle_call({:leave, entity_id, server_id, nip, counter}, _, state) do
    new_entity =
      entity_id
      |> get_entry_entity()
      |> leave_entity(server_id, nip, counter)

    update_ets(@ets_table_entity, entity_id, new_entity)

    {:reply, :ok, state}
  end

  @spec handle_call(:gc, term, term) ::
    {:reply, :ok, term}
  def handle_call(:gc, _, state) do
    table_server = :ets.match_object(@ets_table_server, :'$1')
    table_entity = :ets.match_object(@ets_table_entity, :'$1')

    gc(table_server, table_entity)

    {:reply, :ok, state}
  end

  @spec handle_call({:invalidate_server, String.t, nip}, term, term) ::
    {:reply, :ok, term}
  def handle_call({:invalidate_server, server_id, nip}, _, state) do
    new_server =
      server_id
      |> get_entry_server()
      |> leave_server(nip)

    update_ets(@ets_table_server, server_id, new_server)

    hespawn fn ->
      table_entity = :ets.match_object(@ets_table_entity, :'$1')
      remove_entities_from_server(table_entity, nip)
    end

    {:reply, :ok, state}
  end

  @spec handle_call({:next_counter, String.t, String.t, nip}, term, term) ::
    {:reply, counter, term}
  def handle_call({:next_counter, entity_id, server_id, nip}, _, state) do
    next_counter =
      @ets_table_entity
      |> :ets.lookup(entity_id)
      |> get_next({server_id, nip})

    {:reply, next_counter, state}
  end

  @spec handle_call({:list_open_channels, String.t}, term, term) ::
    {:reply, [formatted_channel_data], term}
  def handle_call({:list_open_channels, server_id}, _, state) do
    result = :ets.lookup(@ets_table_server, server_id)

    server_list =
      if Enum.empty?(result) do
        nil
      else
        [{_server_id, channels}] = result

        Enum.map(channels, fn {{network_id, ip}, counter} ->
          %{
            network_id: Network.ID.cast!(network_id),
            ip: ip,
            counter: counter
          }
        end)
      end

    {:reply, server_list, state}
  end

  docp """
  This method holds the logic for adding a new server to the ETS tables.
  It simply verifies whether the {server, nip, counter} already exists. If so,
  it ignores the request to add to the table. This ensures we won't have any
  repeated entries on the database.
  """
  @spec join_server([server_entry_data], [entity_entry_data], term) ::
    {[server_entry_data], [entity_entry_data]}
  defp join_server(entry_server, entry_entity, {server_id, nip, counter}) do
    new_server =
      if Enum.empty?(entry_server) do
        [{nip, counter}]
      else
        exists? =
          Enum.find(entry_server, fn {entry_nip, entry_counter} ->
            entry_nip == nip and entry_counter == counter
          end)

        if exists? do
          entry_server
        else
          entry_server ++ [{nip, counter}]
        end
      end

    new_entity = entry_entity ++ [{server_id, nip, counter}]

    {new_server, new_entity}
  end

  docp """
  Given the server entry, figure out the next counter to be used for that
  specific server and nip.

  Counter is a sequential index which may have gaps in it (0, 1, 3, 4), in which
  case the algorithm below returns the gap first (in the example, 2). If no gap
  is found, return the next one (in the example it would be 5).
  """
  @spec get_next([] | [entity_entry_data], {String.t, nip}) ::
    next_counter :: counter
  defp get_next([], _),
    do: 0
  defp get_next([{_entity_id, servers}], {server_id, nip}) do
    used_counters =
      servers
      |> Enum.reduce([], fn {entry_server_id, entry_nip, counter}, acc ->
        if entry_server_id == server_id and entry_nip == nip do
          acc ++ [counter]
        else
          acc
        end
      end)
      |> Enum.uniq()
      |> Enum.sort()

    max = List.last(used_counters) || 0

    gap =
      0..max
      |> Enum.reduce_while(false, fn index, _acc ->
        if Enum.member?(used_counters, index) do
          {:cont, false}
        else
          {:halt, index}
        end
      end)

    if gap do
      gap
    else
      max + 1
    end
  end

  @spec remove_entities_from_server(entity_table, nip) ::
    term
  defp remove_entities_from_server(entity_table, nip) do
    Enum.each(entity_table, fn {entity_id, entry_servers} ->
      new_entry_servers =
        Enum.reject(entry_servers, fn {_server, entry_nip, _counter} ->
          entry_nip == nip
        end)

      unless new_entry_servers == entry_servers do
        update_ets(@ets_table_entity, entity_id, new_entry_servers)
      end
    end)
  end

  docp """
  Replaces the corresponding value with the new list. If this list is empty,
  however, instead of replacing we'll remove the entry altogether.
  """
  @spec update_ets(
    server_table_name | entity_table_name,
    key :: String.t,
    server_entry_data | entity_entry_data | [])
  ::
    term
  defp update_ets(table, id, value) do
    if Enum.empty?(value) do
      :ets.delete(table, id)
    else
      :ets.insert(table, {id, value})
    end
  end

  docp """
  Garbage collection implementation. There's always room for optimization.
  """
  @spec gc(server_table, entity_table) ::
    term
  defp gc(servers_table, entities_table) do
    servers = Enum.map(servers_table, fn {entry_id, _} -> entry_id end)

    Enum.map(servers, fn server_id ->

      in_use? =
        Enum.reduce_while(entities_table, false, fn {_, entry_servers}, _a1 ->

          found? =
            Enum.reduce_while(entry_servers, false, fn {s_id, _, _}, _a2 ->
              if s_id == server_id do
                {:halt, true}
              else
                {:cont, false}
              end
            end)

          if found? do
            {:halt, true}
          else
            {:cont, false}
          end
        end)

      {server_id, in_use?}
    end)
    |> Enum.each(&remove_unused_server/1)
  end

  @spec remove_unused_server({server_id :: String.t, in_use? :: boolean}) ::
    term
  defp remove_unused_server({_, true}),
    do: :noop
  defp remove_unused_server({server_id, false}),
    do: :ets.delete(@ets_table_server, server_id)

  @spec leave_server([server_entry_data], nip) ::
    [server_entry_data]
  defp leave_server(entry, nip) do
    Enum.reject(entry, fn {entry_nip, _} ->
      entry_nip == nip
    end)
  end

  @spec leave_entity([entity_entry_data], String.t, nip, counter) ::
    [entity_entry_data]
  defp leave_entity(entry, server_id, nip, counter) do
    Enum.reject(entry, fn {entry_server, entry_nip, entry_count} ->
      entry_server == server_id and entry_nip == nip and entry_count == counter
    end)
  end

  @spec get_entry_server(server_id :: String.t) ::
    [server_entry_data]
  defp get_entry_server(server_id),
    do: get_entry(@ets_table_server, server_id)

  @spec get_entry_entity(entity_id :: String.t) ::
    [entity_entry_data]
  defp get_entry_entity(entity_id),
    do: get_entry(@ets_table_entity, entity_id)

  defp get_entry(table, key) do
    table
    |> :ets.lookup(key)
    |> case do
        [{_key, entry}] ->
          entry
        [] ->
          []
       end
  end
end
