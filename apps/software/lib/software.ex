defmodule HELM.Software.App do
  use Application

  alias HELM.Software

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Software.Repo, []),
      worker(Software.Service, []),
    ]

    opts = [strategy: :one_for_one, name: HELM.Software.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
