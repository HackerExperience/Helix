defmodule HELM.Entity.Service do
  use GenServer

  alias HELM.Entity
  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :entity_service)
  end

  @doc false
  def handle_broker_cast(pid, "event:account:created", id, _request),
    do: GenServer.cast(pid, {:account, :created, id})

  @doc false
  def handle_broker_call(pid, "entity:create", struct, _request) do
    reply = GenServer.call(pid, {:entity, :create, struct})
    {:reply, reply}
  end

  def init(_args) do
    Broker.subscribe("event:account:created", cast: &handle_broker_cast/4)
    Broker.subscribe("entity:create", call: &handle_broker_call/4)

    {:ok, nil}
  end

  def handle_cast({:account, :created, id}, state) do
    Entity.Controller.new_entity(%{account_id: id})
    {:noreply, state}
  end

  def handle_call({:entity, :create, struct}, _from, state) do
    return = Entity.Controller.new_entity(struct)

    {:reply, return, state}
  end
end