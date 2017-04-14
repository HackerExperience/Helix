defmodule Helix.Process.Supervisor do
  @moduledoc false

  use Supervisor

  alias Helix.Process.Repo
  alias Helix.Process.Service.Local.TOP.Supervisor, as: TOP

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  @doc false
  def init(_) do
    children = [
      worker(Repo, []),
      supervisor(TOP, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
