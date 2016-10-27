defmodule HELM.Process.App do
  use Application

  alias HELM.Process.Repo
  alias HELM.Process.Controller.ProcessService

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Repo, []),
      worker(ProcessService, []),
    ]

    opts = [strategy: :one_for_one, name: HELM.Process.Supervisor]
    Supervisor.start_link(children, opts)
  end
end