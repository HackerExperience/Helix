defmodule Helix.Hardware.App do

  use Application

  alias Helix.Hardware.Repo
  alias Helix.Hardware.Controller.HardwareService

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Repo, []),
      worker(HardwareService, [])
    ]

    opts = [strategy: :one_for_one, name: Helix.Hardware.Supervisor]
    Supervisor.start_link(children, opts)
  end
end