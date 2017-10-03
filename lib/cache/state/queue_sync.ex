defmodule Helix.Cache.State.QueueSync do

  require Logger
  use GenServer

  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  @interval 15 * 1000  #15s
  @registry_name :cache_queue_sync

  def start_link(interval \\ @interval) do
    GenServer.start_link(__MODULE__, interval, name: @registry_name)
  end

  def set_interval(interval) do
    GenServer.call(@registry_name, {:set_interval, interval})
  end

  def init(interval) do
    timer_ref = schedule(interval)
    {:ok, %{timer_ref: timer_ref, interval: interval}}
  end

  def handle_call({:set_interval, new_interval}, _from, state) do
    Process.cancel_timer(state.timer_ref)
    new_timer = schedule(new_interval)
    {:reply, :ok, %{timer_ref: new_timer, interval: new_interval}}
  end

  def handle_info(:sync, state) do
    StatePurgeQueue.sync()
    timer_ref = schedule(state.interval)
    {:noreply, %{state | timer_ref: timer_ref}}
  end

  defp schedule(interval),
    do: Process.send_after(@registry_name, :sync, interval)
end
