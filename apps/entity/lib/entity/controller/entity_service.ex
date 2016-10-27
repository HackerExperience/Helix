defmodule HELM.Controller.EntityService do
  use GenServer

  alias HELF.Broker
  alias HELM.Entity.Controller.Entity, as: CtrlEntity

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :entity_service)
  end

  def init(_args) do
    Broker.subscribe("event:account:created", cast: &handle_broker_cast/4)
    Broker.subscribe("entity:create", call: &handle_broker_call/4)
    Broker.subscribe("entity:find", call: &handle_broker_call/4)
    {:ok, nil}
  end

  @doc false
  def handle_broker_cast(pid, "event:account:created", id, _request),
    do: GenServer.cast(pid, {:account_created, id})

  @doc false
  def handle_cast({:account_created, id}, state) do
    CtrlEntity.action_create(%{account_id: id})
    {:noreply, state}
  end

  @doc false
  def handle_broker_call(pid, "entity:create", params, _request),
    do: GenServer.call(pid, {:entity_create, params})
  def handle_broker_call(pid, "entity:find", id, _request),
    do: GenServer.call(pid, {:entity_find, id})

  @doc false
  def handle_call({:entity_create, params}, _from, state) do
    return = CtrlEntity.action_create(params)
    {:reply, {:reply, return}, state}
  end
end