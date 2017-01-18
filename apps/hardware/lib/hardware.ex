defmodule Helix.Hardware.App do

  use Application

  alias Helix.Hardware.Controller.HardwareService
  alias Helix.Hardware.Repo

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