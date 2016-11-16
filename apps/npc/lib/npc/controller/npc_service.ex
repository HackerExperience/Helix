defmodule HELM.NPC.Controller.NPCService do

  use GenServer

  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :npc_service)
  end

  def handle_broker_call(pid, "npc:create", struct, _request) do
    reply = GenServer.call(pid, {:npc, :create, struct})
    {:reply, reply}
  end

  def init(_args) do
    Broker.subscribe("npc:create", call: &handle_broker_call/4)
    {:ok, nil}
  end

  def handle_call({:npc, :create, _struct}, _from, state) do
    {:noreply, state}
  end
end