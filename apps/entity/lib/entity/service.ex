defmodule HELM.Entity.Service do
  use GenServer

  alias HELM.Entity
  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :entity_service)
  end

  def init(_args) do
    Broker.subscribe(:entity, "event:account:created", cast:
      fn _, _, id ->
        Entity.Controller.create(%{ account_id: id })
      end)

    # TODO: fix this return
    {:ok, %{}}
  end

end
