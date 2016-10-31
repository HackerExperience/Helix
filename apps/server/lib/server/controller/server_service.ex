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
  def handle_broker_cast(pid, "event:entity:created", entity_id, _request),
    do: GenServer.cast(pid, {:server, :create, entity_id})

  @doc false
  def handle_broker_call(pid, "server:create", entity_id, _request) do
    response = GenServer.call(pid, {:server, :create, entity_id})
    {:reply, response}
  end
  def handle_broker_call(pid, "server:attach", {id, mobo}, _request) do
    response = GenServer.call(pid, {:server, :attach, id, mobo})
    {:reply, response}
  end
  def handle_broker_call(pid, "server:detach", id, _request) do
    response = GenServer.call(pid, {:server, :detach, id})
    {:reply, response}
  end

  @doc false
  def handle_cast({:server, :create, entity_id}, state) do
    create_server(entity_id)
    {:noreply, state}
  end

  @doc false
  def handle_call({:server, :create, entity_id}, _from, state) do
    return = create_server(entity_id)
    {:reply, return, state}
  end
  def handle_call({:server, :attach, id, mobo}, _from, state) do
    {status, _} = CtrlServers.attach(id, mobo)
    {:reply, status, state}
  end
  def handle_call({:server, :detach, id}, _from, state) do
    {status, _} = CtrlServers.detach(id)
    {:reply, status, state}
    end
  end

  defp create_server(entity_id) do
    with {:ok, server} <- CtrlServers.create(%{entity_id: entity_id}) do
      Broker.cast("event:server:created", server.server_id)
      {:ok, server.server_id}
    end
  end
end