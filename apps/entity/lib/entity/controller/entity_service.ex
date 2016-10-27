defmodule HELM.Controller.EntityService do
  use GenServer

  alias HELM.Entity.Controller.Entity, as: CtrlEntity

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :entity_service)
  end

  def init(_args) do
    {:ok, nil}
  end

  def handle_cast({:account, :created, id}, state) do
    CtrlEntity.create(%{account_id: id})
    {:noreply, state}
  end

  def handle_call({:entity, :create, struct}, _from, state) do
    return = CtrlEntity.create(struct)

    {:reply, return, state}
  end
end