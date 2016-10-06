defmodule HELM.Hardware.Service do
  use GenServer

  alias HELM.Hardware
  alias HELF.Broker

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :hardware_service)
  end

  def init(_args) do
    {:ok, %{}}
  end
end
