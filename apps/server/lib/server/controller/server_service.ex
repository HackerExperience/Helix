defmodule HELM.Server.Controller.ServerService do
  use GenServer

  alias HELM.Server.Controller.Server, as: CtrlServers
  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :server)
  end

  @doc false
  def init(_args) do
    Broker.subscribe("event:entity:created", cast: &handle_broker_cast/4)
    Broker.subscribe("server:create", call: &handle_broker_call/4)
    Broker.subscribe("server:attach", call: &handle_broker_call/4)
    Broker.subscribe("server:detach", call: &handle_broker_call/4)

    {:ok, nil}
  end

  @doc false
  def handle_broker_cast(pid, "event:entity:created", id, _request),
    do: GenServer.cast(pid, {:entity_created, id})

  @doc false
  def handle_cast({:entity_created, id}, state) do
    CtrlServers.create(%{entity_id: id})
    {:noreply, state}
  end

  @doc false
  def handle_broker_call(pid, "server:create", struct, _request),
    do: GenServer.call(pid, {:server_create, struct})
  def handle_broker_call(pid, "server:attach", {server, mobo}, _request),
    do: GenServer.call(pid, {:server_attach, server, mobo})
  def handle_broker_call(pid, "server:detach", server, _request),
    do: GenServer.call(pid, {:server_detach, server})

  @doc false
  def handle_call({:server_create, struct}, _from, state) do
    reply = case CtrlServers.create(struct) do
      {:ok, schema} -> {:ok, schema.server_id}
      {:error, _} -> :error
    end
    {:reply, {:reply, reply}, state}
  end
  def handle_call({:server_attach, server, mobo}, _from, state) do
    reply = case CtrlServers.attach(server, mobo) do
      {:ok, _} -> :ok
      {:error, _} -> :error
    end
    {:reply, {:reply, reply}, state}
  end
  def handle_call({:server_detach, server}, _from, state) do
    reply = case CtrlServers.detach(server) do
      {:ok, _} -> :ok
      {:error, _} -> :error
    end
    {:reply, {:reply, reply}, state}
  end
end