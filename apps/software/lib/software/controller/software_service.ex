defmodule HELM.Software.Service do
  use GenServer

  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :software)
  end

  def init(_args) do
    {:ok, %{}}
  end
end
