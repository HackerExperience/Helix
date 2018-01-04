defmodule Helix.Process.Supervisor do
  @moduledoc false

  use Supervisor

  alias Helix.Process.Repo

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  @doc false
  def init(_) do
    children = [
      supervisor(Repo, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
