defmodule Helix.Hardware.App do

  use Application

  alias Helix.Hardware.Repo, as: HardwareRepo
  alias Helix.Hardware.Controller.HardwareService, as: HardwareSvc

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(HardwareRepo, []),
      worker(HardwareSvc, [])
    ]

    opts = [strategy: :one_for_one, name: Helix.Hardware.Supervisor]
    Supervisor.start_link(children, opts)
  end
end