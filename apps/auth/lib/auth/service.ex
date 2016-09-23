defmodule HELM.Auth.Service do
  use GenServer

  alias HELF.Broker
  alias HELM.Auth.JWT

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :auth_service)
  end

  def init(_args) do
    Broker.subscribe(:auth, "auth:create", call:
      fn pid,_,id,timeout ->
        GenServer.call(pid, {:auth_create, id}, timeout)
      end)

    Broker.subscribe(:auth, "auth:verify", call:
      fn pid,_,jwt,timeout ->
        GenServer.call(pid, {:auth_verify, id}, timeout)
      end)

    {:ok, %{}}
  end

  def handle_call({:auth_create, id}, _from, state) do
    result = Auth.JWT.generate(id)
    {:reply, result, state}
  end

  def handle_call({:auth_verify, jwt}, _from, state) do
    result = Auth.JWT.verify(jwt)
    {:reply, result, state}
  end
end
