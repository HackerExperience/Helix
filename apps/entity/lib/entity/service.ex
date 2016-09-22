defmodule HELM.Entity.Service do
  use GenServer

  alias HELM.Entity
  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :entity_service)
  end

  def init(_args) do
    register_cast
    register_call
    {:ok, %{}}
  end

  # Asynchronous subscriptions
  defp register_cast do
    Broker.subscribe(:entity, "event:account:created", cast: &cast_account_created/3)
  end

  # Try to create an Entity for given `account_id`
  defp cast_account_created(_, _, account_id) do
  end

  # Synchronous subscriptions
  defp register_call do
    Broker.subscribe(:entity, "entity:create", cast: &call_entity_create/4)
  end

  # Try to create a Entity to given struct
  defp call_entity_create(_, _, struct, _timeout) do
    Entity.Controller.new_entity(struct)
    {:reply, {:ok, "lel"}}
  end
end
