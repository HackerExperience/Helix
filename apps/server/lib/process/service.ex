defmodule HELM.Server.Service do
  use GenServer

  alias HELM.Server
  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :server_service)
  end

  def init(_args) do
    Broker.subscribe(:server_service, "server:create", call:
      fn _,_,server,_ ->
        response = Server.Controller.new_server(server)
        {:reply, response}
      end)

    Broker.subscribe(:server_service, "server:remove", call:
      fn _,_,args,_ ->
        response = Server.Controller.remove_server(args.server_id)
        {:reply, response}
      end)
    {:ok, %{}}
  end
end
