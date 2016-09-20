defmodule HELM.Auth.Service do
  use GenServer

  alias HELF.Broker
  alias HELM.Auth.JWT

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :auth_service)
  end

  def init(_args) do
    Broker.subscribe(:auth, "auth:create", call:
      fn _,_,id,_ ->
        Auth.JWT.generate(id)
      end)

    Broker.subscribe(:auth, "auth:verify", call:
      fn _,_,jwt,_ ->
          Auth.JWT.verify(jwt)
      end)

    {:ok, %{}}
  end
end
