defmodule HELM.Controller.EntityService do
  use GenServer

  alias HELM.Entity.Controller.Entities, as: CtrlEntities

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :entity_service)
  end

  def init(_args) do
    Broker.subscribe("entity:create", call: &handle_broker_call/4)
    {:ok, nil}
  end

  def handle_cast({:account, :created, id}, state) do
    CtrlEntities.create(%{account_id: id})
    {:noreply, state}
  end

  def handle_call({:entity, :create, struct}, _from, state) do
    return = CtrlEntities.create(struct)

    {:reply, return, state}
  end
end