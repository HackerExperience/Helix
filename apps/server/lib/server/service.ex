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
        response = GenServer.cast(pid, {:entity_created, id})
        {:noreply, :ok}
      end)

    Broker.subscribe(:server_service, "server:create", call:
      fn pid,_,struct,timeout ->
        case GenServer.call(pid, {:create, struct}, timeout) do
          {:ok, server_id} -> {:reply, {:ok, server_id}}
          error -> error
        end
      end)

    Broker.subscribe(:server_service, "server:attach", call:
      fn pid,_,{server, mobo},timeout ->
        case GenServer.call(pid, {:attach, server, mobo}, timeout) do
          {:ok, server_id} -> {:reply, {:ok, server_id}}
          error -> error
        end
      end)

    Broker.subscribe(:server_service, "server:detach", call:
      fn pid,_,server,timeout ->
        case GenServer.call(pid, {:detach, server}, timeout) do
          {:ok, server_id} -> {:reply, {:ok, server_id}}
          error -> error
        end
      end)
    {:ok, %{}}
  end

  def handle_cast({:entity_created, id}, state) do
    Server.Controller.create(%{entity_id: id, poi_id: "", motherboard_id: ""})
    {:noreply, state}
  end

  def handle_call({:create, struct}, _from, state) do
    case Server.Controller.create(struct) do
      {:ok, schema} -> {:reply, {:ok, schema.server_id}, state}
      {:error, _} -> {:reply, :error, state}
    end
  end

  def handle_call({:attach, server, mobo}, _from, state) do
    case Server.Controller.attach(server, mobo) do
      {:ok, schema} -> {:reply, :ok, state}
      {:error, _} -> {:reply, :error, state}
    end
  end

  def handle_call({:detach, server}, _from, state) do
    case Server.Controller.detach(server) do
      {:ok, schema} -> {:reply, :ok, state}
      {:error, _} -> {:reply, :error, state}
    end
  end
end
