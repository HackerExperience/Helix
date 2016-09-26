defmodule HELM.Process.App do
  use Application

  alias HELM.Process

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Process.Repo, []),
      worker(Process.Service, []),
    ]

    opts = [strategy: :one_for_one, name: HELM.Process.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
