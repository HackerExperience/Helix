defmodule HELM.Hardware.App do

  use Application

  alias HELM.Hardware.Repo, as: HardwareRepo
  alias HELM.Hardware.Controller.HardwareService, as: HardwareSvc

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(HardwareRepo, []),
      worker(HardwareSvc, [])
    ]

    opts = [strategy: :one_for_one, name: HELM.Hardware.Supervisor]
    Supervisor.start_link(children, opts)
  end
end