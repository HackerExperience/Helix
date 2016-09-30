defmodule HELM.Server.Service do
  use GenServer

  alias HELM.Server
  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :server_service)
  end

  def init(_args) do
    Broker.subscribe(:server_service, "event:entity:created", cast:
      fn pid,_,id ->
        GenServer.cast(pid, {:entity_created, id})
      end)

    Broker.subscribe(:server_service, "server:create", call:
      fn pid,_,struct,timeout ->
        case GenServer.call(pid, {:server_create, struct}, timeout) do
          {:ok, server_id} -> {:reply, {:ok, server_id}}
          error -> error
        end
      end)

    {:ok, %{}}
  end

  def handle_cast({:entity_created, id}, state) do
    Server.Controller.new_server(%{entity_id: id, poi_id: "", motherboard_id: ""})
    {:noreply, state}
  end

  def handle_call({:server_create, struct}, _from, state) do
    case Server.Controller.new_server(struct) do
      {:ok, schema} -> {:reply, {:ok, schema.server_id}, state}
      {:error, _} -> {:reply, :error, state}
    end
  end
end