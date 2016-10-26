defmodule HELM.NPC.App do
  use Application

  alias HELM.NPC.Model.Repo
  alias HELM.NPC.Controller.NPCService

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Repo, []),
      worker(NPCService, []),
    ]

    opts = [strategy: :one_for_one, name: HELM.NPC.Supervisor]
    Supervisor.start_link(children, opts)
  end
end