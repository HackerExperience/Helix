defmodule HELM.NPC.Service do
  use GenServer

  alias HELM.NPC
  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :npc_service)
  end

  def init(_args) do
    Broker.subscribe(:npc_service, "npc:create", call:
      fn pid,_,struct,timeout ->
        case GenServer.call(pid, {:npc_create, struct}, timeout) do
          {:ok, npc_id} -> {:reply, {:ok, npc_id}}
          error -> error
        end
      end)

    {:ok, %{}}
  end

  def handle_call({:npc_create, struct}, _from, state) do
    case Entity.Controller.new_npc(struct) do
      {:ok, schema} -> {:reply, {:ok, schema.npc_id}, state}
      {:error, _} -> {:reply, :error, state}
    end
  end
end
