defmodule HELM.Entity.Service do
  use GenServer

  alias HELM.Entity
  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :entity_service)
  end

  def init(_args) do
    Broker.subscribe(:entity_service, "event:account:created", cast:
      fn pid,_,id ->
        GenServer.cast(pid, {:account_created, id})
      end)

    Broker.subscribe(:entity_service, "entity:create", call:
      fn pid,_,struct,timeout ->
        case GenServer.call(pid, {:entity_create, struct}, timeout) do
          {:ok, entity_id} -> {:reply, {:ok, entity_id}}
          error -> error
        end
      end)

    {:ok, %{}}
  end

  def handle_cast({:account_created, id}, state) do
    Entity.Controller.new_entity(%{account_id: id})
    {:noreply, state}
  end

  def handle_call({:entity_create, struct}, _from, state) do
    case Entity.Controller.new_entity(struct) do
      {:ok, schema} -> {:reply, {:ok, schema.entity_id}, state}
      {:error, _} -> {:reply, :error, state}
    end
  end
end
