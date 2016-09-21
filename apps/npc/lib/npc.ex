defmodule HELM.NPC.App do
  use Application

  alias HELM.NPC

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(NPC.Repo, []),
      worker(NPC.Service, []),
    ]

    opts = [strategy: :one_for_one, name: HELM.NPC.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
