defmodule HELM.Entity.Service do
  use GenServer

  alias HELM.Entity
  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :entity_service)
  end

  def init(_args) do
    Broker.subscribe(:entity, "entity:create", cast:
      fn _, _,params ->
        Entity.Controller.create(params)
      end)

    {:ok, %{}}
  end
end
