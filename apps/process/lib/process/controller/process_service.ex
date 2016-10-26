defmodule HELM.Process.Service do
  use GenServer

  alias HELM.Process, warn: false
  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :process_service)
  end

  @doc false
  def handle_broker_call(pid, "process:create", struct, _request) do
    reply = GenServer.call(pid, {:process, :create, struct})
    {:reply, reply}
  end

  @doc false
  def init(_args) do
    Broker.subscribe("process:create", call: &handle_broker_call/4)

    {:ok, nil}
  end

  @doc false
  def handle_call({:process_create, _struct}, _from, _state) do
    # FIXME
    # reply = case Entity.Controller.new_process(struct) do
    #   {:ok, schema} ->
    #     {:ok, schema.process_id}
    #   {:error, _} ->
    #     :error
    # end
    #
    # {:reply, reply, state}

    raise RuntimeError
  end
end