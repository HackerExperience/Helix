defmodule Helix.Cache.State.PurgeQueue do

  use GenServer

  @registry_name :cache_purge_queue
  @ets_table_name :ets_cache_purge_queue

  # Client API

  def start_link do
    {:ok, pid} = GenServer.start_link(__MODULE__, [], name: @registry_name)
    GenServer.call(@registry_name, :setup)
    {:ok, pid}
  end

  def lookup(model, key) do
    GenServer.call(@registry_name, {:lookup, model, key})
  end

  def queue(model, key) do
    GenServer.call(@registry_name, {:add, model, key})
  end

  def queue_multiple(entry_list) do
    GenServer.call(@registry_name, {:add_multiple, entry_list})
  end

  def unqueue(model, key) do
    GenServer.cast(@registry_name, {:remove, model, key})
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
    queued? = :ets.lookup(@ets_table_name, {model, key})
    |> case do
         [] ->
           false
         [_] ->
           true
       end

    {:reply, queued?, state}
  end

  def handle_call({:add, model, key}, _from, state) do
    :ets.insert(@ets_table_name, {{model, key}})
    {:reply, :ok, state}
  end

  def handle_call({:add_multiple, entry_list}, _from, state) do
    Enum.each(entry_list, fn({model, key}) ->
      :ets.insert(@ets_table_name, {{model, key}})
    end)
    {:reply, :ok, state}
  end

  def handle_cast({:remove, model, key}, state) do
    :ets.delete(@ets_table_name, {model, key})
    {:noreply, state}
  end

end
