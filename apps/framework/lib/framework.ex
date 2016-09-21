defmodule HELM.Framework.App do
  use Application

  alias HELF.Router

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(HeBroker, []),
      supervisor(Router, [])
    ]

    opts = [strategy: :one_for_one, name: HELM.Framework.Supervisor]

    {:ok, _} = Supervisor.start_link(children, opts)
  end
end
