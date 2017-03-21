defmodule Helix.NPC.Controller.NPCService do

  use GenServer

  alias HELF.Broker

  @spec start_link() :: GenServer.on_start
  def start_link do
    GenServer.start_link(__MODULE__, [], name: :npc_service)
  end

  @doc false
  def handle_broker_call(pid, "npc.create", params, _request) do
    reply = GenServer.call(pid, {:npc, :create, params})
    {:reply, reply}
  end

  @spec init(any) :: {:ok, nil}
  @doc false
  def init(_args) do
    Broker.subscribe("npc.create", call: &handle_broker_call/4)
    {:ok, nil}
  end

  @spec handle_call({:npc, :create, any}, GenServer.from, nil) :: {:noreply, nil}
  @doc false
  def handle_call({:npc, :create, _struct}, _from, state) do
    {:noreply, state}
  end
end