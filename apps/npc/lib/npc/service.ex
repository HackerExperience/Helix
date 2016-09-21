defmodule HELM.NPC.Service do
  use GenServer

  alias HELM.NPC
  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :npc_service)
  end

  def init(_args) do
    {:ok, %{}}
  end
end
