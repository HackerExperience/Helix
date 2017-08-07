defmodule Helix.Cache.State.PurgeQueue do

  @moduledoc """
  StatePurgeQueue is responsible for handling information about cache entries
  that have been marked as purged/invalid. Usually this happens when the
  data is being repopulated.

  The usual life-cycle for the PurgeQueue (and Cache service) is:

  1) External module asks for information from the cache
  2) Cache checks whether such information is marked as purged (`lookup/2`)
    2.1) If it's not on the purge queue, it will attempt to fetch the DB.
      2.1.1) If it's on the DB and hasn't expired, the entry is returned. Go to 3.1
      2.1.2) If it's not on the DB or it is expired, entry is generated. Go to 3.2
    2.2) If it's on the purge queue, entry is generated. Go to 3.2. [1]
  3.1) Entry already exists and is valid. Skip population. Go to 4.
  3.2) Entry does not exists or isn't valid. New data is populated.
    3.2.1) Gathering necessary data for population
    3.2.2) Add object to the queue
    3.2.3) Immediately return the entry. Go to 4. On another thread, go to 3.2.4
    3.2.4) Asynchronously add that data to the DB
    3.2.5) Once that data has been added, unqueue the object from the PurgeQueue
  4) Return the data.

  ### Notes

  [1] - There's room for an improvement on the situation where:
  - Object exists on the queue; and
  - Another module requested that same object.

  As it is right now, subsequent calls will each one spawn a new thread to
  populate the cache. That's inefficient, but GoodEnough. If needed, a nice
  solution would be to create a `sync` call on the PurgeQueue, so the relevant
  entry would be cached synchronously, and subsequent calls would wait, in a
  blocking process, to the removal from the queue. In other words: do not
  attempt to re-populate if there already is an entry in the PurgeQueue.
  """

  use GenServer

  alias Helix.Cache.Internal.Purge, as: PurgeInternal

  @registry_name :cache_purge_queue
  @ets_table_name :ets_cache_purge_queue

  # Client API

  def start_link do
    {:ok, pid} = GenServer.start_link(__MODULE__, [], name: @registry_name)
    GenServer.call(@registry_name, :setup)
    {:ok, pid}
  end

  def lookup(model, key = %_{id: _}),
    do: lookup(model, to_string(key))
  def lookup(model, key) when not is_tuple(key),
    do: lookup(model, {key})
  def lookup(model, key),
    do: GenServer.call(@registry_name, {:lookup, model, key})

  def queue(model, key = %_{id: _}, action),
    do: queue(model, to_string(key), action)
  def queue(model, key, action) when not is_tuple(key),
    do: queue(model, {key}, action)
  def queue(model, key, action) do
    GenServer.call(@registry_name, {:add, model, key, action})
  end

  def queue_multiple(entry_list, action),
    do: GenServer.call(@registry_name, {:add_multiple, entry_list, action})

  def unqueue(model, key = %_{id: _}, action),
    do: unqueue(model, to_string(key), action)
  def unqueue(model, key, action) when not is_tuple(key),
    do: unqueue(model, {key}, action)
  def unqueue(model, key, action),
    do: GenServer.cast(@registry_name, {:remove, model, key, action})

  def sync do
    map(&exec_sync/1)
  end

  defp exec_sync({domain, args, :update}) do
    PurgeInternal.update(domain, args)
    unqueue(domain, args, :update)
  end
  defp exec_sync({domain, args, :purge}) do
    PurgeInternal.purge(domain, args)
    unqueue(domain, args, :purge)
  end

  defp map(fun) do
    :ets.safe_fixtable(@ets_table_name, true)
    map(:ets.first(@ets_table_name), fun)
    :ets.safe_fixtable(@ets_table_name, false)
  end
  defp map(el, fun) do
    case el do
      :'$end_of_table' ->
        :ok
      d ->
        fun.(d)
        map(:ets.next(@ets_table_name, d), fun)
    end
  end

  # Callbacks

  def init(_) do
    {:ok, []}
  end

  def handle_call(:setup, _from, state) do
    :ets.new(@ets_table_name, [:set, :protected, :named_table])
    {:reply, :ok, state}
  end

  def handle_call({:lookup, model, key}, _from, state) do
    queued? = :ets.match_object(@ets_table_name, {{model, key, :'_'}})
    |> case do
         [] ->
           false
         _ ->
           true
       end

    {:reply, queued?, state}
  end

  def handle_call({:add, model, key, action}, _from, state) do
    :ets.insert(@ets_table_name, {{model, key, action}})
    {:reply, :ok, state}
  end

  def handle_call({:add_multiple, entry_list, action}, _from, state) do
    Enum.each(entry_list, fn({model, key}) ->
      :ets.insert(@ets_table_name, {{model, key, action}})
    end)

    {:reply, :ok, state}
  end

  def handle_cast({:remove, model, key, action}, state) do
    :ets.delete(@ets_table_name, {model, key, action})
    {:noreply, state}
  end

end
