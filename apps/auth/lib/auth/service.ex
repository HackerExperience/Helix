defmodule HELM.Auth.Service do
  use GenServer

  alias HELF.Broker
  alias HELM.Auth

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :auth_service)
  end

  @doc false
  def handle_broker_call(pid, "auth:create", id, _request),
    do: GenServer.call(pid, {:auth, :create, id})
  def handle_broker_call(pid, "auth:verify", jwt, _request),
    do: GenServer.call(pid, {:auth, :verify, jwt})


  def init(_args) do
    Broker.subscribe("auth:create", call: &handle_broker_call/4)
    Broker.subscribe("auth:verify", call: &handle_broker_call/4)

    {:ok, nil}
  end

  def handle_call({:auth, :create, id}, _from, state) do
    result = Auth.JWT.generate(id)
    {:reply, result, state}
  end

  def handle_call({:auth, :verify, jwt}, _from, state) do
    result = Auth.JWT.verify(jwt)
    {:reply, result, state}
  end
end