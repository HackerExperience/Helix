defmodule Helix.Cache.State.Supervisor do
  @moduledoc false

  use Supervisor

  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  @spec start_link() ::
  Supervisor.on_start
  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def init(_) do
    children = [
      worker(StatePurgeQueue, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end

