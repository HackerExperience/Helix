defmodule Helix.NPC.App do

  use Application

  alias Helix.NPC.Controller.NPCService
  alias Helix.NPC.Repo

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Repo, []),
      worker(NPCService, [])
    ]

    opts = [strategy: :one_for_one, name: Helix.NPC.Supervisor]
    Supervisor.start_link(children, opts)
  end
end