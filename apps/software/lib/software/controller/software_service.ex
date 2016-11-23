defmodule HELM.Software.Controller.SoftwareService do

  use GenServer

  @spec start_link() :: GenServer.on_start
  def start_link do
    GenServer.start_link(__MODULE__, [], name: :software)
  end

  @spec init(any) :: {:ok, term}
  @doc false
  def init(_) do
    {:ok, %{}}
  end
end