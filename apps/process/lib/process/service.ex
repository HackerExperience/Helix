defmodule HELM.Process.Service do
  use GenServer

  alias HELM.Process
  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :process_service)
  end

  def init(_args) do
    Broker.subscribe(:process_service, "process:create", call:
      fn _,_,process,_ ->
        response = Process.Controller.new_process(process)
        {:reply, response}
      end)

    Broker.subscribe(:process_service, "process:remove", call:
      fn _,_,args,_ ->
        response = Process.Controller.remove_process(args.process_id)
        {:reply, response}
      end)
    {:ok, %{}}
  end
end
