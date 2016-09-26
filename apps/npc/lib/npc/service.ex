defmodule HELM.NPC.Service do
  use GenServer

  alias HELM.NPC
  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :npc_service)
  end

  def init(_args) do
    Broker.subscribe(:npc_service, "npc:create", call:
      fn _,_,npc,_ ->
        response = NPC.Controller.new_npc(npc)
        {:reply, response}
      end)

    Broker.subscribe(:npc_service, "npc:remove", call:
      fn _,_,args,_ ->
        response = NPC.Controller.remove_npc(args.npc_id)
        {:reply, response}
      end)
    {:ok, %{}}
  end
end
