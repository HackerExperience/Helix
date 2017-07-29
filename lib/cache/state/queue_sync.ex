defmodule Helix.Cache.State.QueueSync do

  require Logger
  use GenServer

  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  @interval 5 * 1000  #30s
  @registry_name :cache_queue_sync

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @registry_name)
  end

  def init(state) do
    schedule()
    {:ok, []}
  end

  def handle_info(:sync, state) do
    sync()
    schedule()
    {:noreply, state}
  end

  def step do
    # Kernel.send(@registry_name, )
    pid = Process.whereis(@registry_name)
    Kernel.send(pid, :sync)
  end

  defp sync do
    StatePurgeQueue.map(&exec_sync/1)
  end

  defp schedule do
    Process.send_after(@registry_name, :sync, @interval)
  end

  defp exec_sync({domain, object}) do
    IO.inspect(domain)
    IO.inspect(object)
    alias Helix.Cache.Internal.Purge, as: PurgeInternal
    # apply(PurgeInternal, :update, [domain] ++ object)
    StatePurgeQueue.unqueue(domain, object)
  end

end
