defmodule HELM.NPC.Service do
  use GenServer

  alias HELM.NPC, warn: false
  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :npc_service)
  end

  @doc false
  def handle_broker_call(pid, "npc:create", struct, _request) do
    reply = GenServer.call(pid, {:npc, :create, struct})
    {:reply, reply}
  end

  @doc false
  def init(_args) do
    Broker.subscribe("npc:create", call: &handle_broker_call/4)

    {:ok, nil}
  end

  @doc false
  def handle_call({:npc, :create, _struct}, _from, state) do
    # FIXME
    # reply = case Entity.Controller.new_npc(struct) do
    #   {:ok, schema} ->
    #     {:ok, schema.npc_id}
    #   {:error, _} ->
    #     :error
    # end
    #
    # {:reply, reply, state}

    {:reply, %RuntimeError{}, state}
  end
end