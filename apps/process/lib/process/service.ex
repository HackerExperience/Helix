defmodule HELM.Process.Service do
  use GenServer

  alias HELM.Process
  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :process_service)
  end

  def init(_args) do
    Broker.subscribe(:process_service, "process:create", call:
      fn pid,_,struct,timeout ->
        case GenServer.call(pid, {:process_create, struct}, timeout) do
          {:ok, process_id} -> {:reply, {:ok, process_id}}
          error -> error
        end
      end)

    {:ok, %{}}
  end

  def handle_call({:process_create, struct}, _from, state) do
    case Entity.Controller.new_process(struct) do
      {:ok, schema} -> {:reply, {:ok, schema.process_id}, state}
      {:error, _} -> {:reply, :error, state}
    end
  end
end
