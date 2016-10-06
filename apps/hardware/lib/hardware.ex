defmodule HELM.Hardware.App do
  use Application

  alias HELM.Hardware

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Hardware.Repo, []),
      worker(Hardware.Service, []),
    ]

    opts = [strategy: :one_for_one, name: HELM.Hardware.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
