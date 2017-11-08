defmodule Helix.Cache.State.QueueSync do

  require Logger
  use GenServer

  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  @interval (if Mix.env == :test,
    do: 999_999_999,  # Never sync during test
    else: 15 * 1000)  # 15s default sync time (on :dev and :prod)

  @registry_name :cache_queue_sync

  def start_link(interval \\ @interval) do
    GenServer.start_link(__MODULE__, interval, name: @registry_name)
  end

  def init(interval) do
    timer_ref = schedule(interval)
    {:ok, %{timer_ref: timer_ref, interval: interval}}
  end

  def handle_info(:sync, state) do
    StatePurgeQueue.sync()
    timer_ref = schedule(state.interval)
    {:noreply, %{state | timer_ref: timer_ref}}
  end

  defp schedule(interval),
    do: Process.send_after(@registry_name, :sync, interval)
end
