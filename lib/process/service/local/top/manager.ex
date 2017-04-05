defmodule Helix.Process.Service.Local.Top.Manager do

  alias Helix.Process.Service.Local.Top.Supervisor

  # TODO: Replace this with a distributed alternative. Maybe using PubSub

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def prepare_top(gateway) do
    pid = get(gateway)

    if pid do
      {:ok, pid}
    else
      Supervisor.start_top(gateway)
    end
  end

  @spec put(HELL.PK.t, pid) ::
    :ok
  @doc false
  def put(gateway, top_server),
    do: GenServer.cast(__MODULE__, {:put, {gateway, top_server}})

  @spec get(HELL.PK.t) ::
    pid | nil
  def get(gateway),
    do: GenServer.call(__MODULE__, {:get, gateway})

  @doc false
  def init(_) do
    {:ok, {%{}, %{}}}
  end

  @doc false
  def handle_cast({:put, {gateway, top_server}}, {name_to_pid, pid_to_name}) do
    Process.monitor(top_server)

    name_to_pid = Map.put(name_to_pid, gateway, top_server)
    pid_to_name = Map.put(pid_to_name, top_server, gateway)

    {:noreply, {name_to_pid, pid_to_name}}
  end

  @doc false
  def handle_call({:get, gateway}, _from, state = {name_to_pid, _}) do
    {:reply, Map.get(name_to_pid, gateway), state}
  end

  @doc false
  def handle_info({:DOWN, _, :process, pid, _}, {name_to_pid, pid_to_name}) do
    {gateway, pid_to_name} = Map.pop(pid_to_name, pid)
    name_to_pid = Map.delete(name_to_pid, gateway)

    {:noreply, {name_to_pid, pid_to_name}}
  end
end
