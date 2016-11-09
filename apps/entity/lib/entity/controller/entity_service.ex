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
  def handle_broker_cast(pid, "event:account:created", id, _request) do
    GenServer.cast(pid, {:entity, :create, :account, id})
  end

  @doc false
  def handle_broker_call(pid, "entity:find", id, _request) do
    response = GenServer.call(pid, {:entity, :find, id})
    {:reply, response}
  end

  @doc false
  def handle_cast({:entity, :create, :account, id}, state) do
    create_entity(%{account_id: id})
    {:noreply, state}
  end

  @doc false
  def handle_call({:entity, :create, params}, _from, state) do
    case create_entity(params) do
      {:ok, entity} -> {:reply, {:ok, entity}, state}
      error -> {:reply, {:ok, error}, state}
    end
  end
  def handle_call({:entity, :find, id}, _from, state) do
    response = CtrlEntity.find(id)
    {:reply, response, state}
  end

  defp create_entity(params) do
    with {:ok, entity} <- CtrlEntity.create(params) do
      Broker.cast("event:entity:created", entity.entity_id)
      {:ok, entity}
    end
  end
end