defmodule HELM.Process.Controller.ProcessService do

  use GenServer

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :process_service)
  end

  def init(_args) do
    {:ok, nil}
  end
end