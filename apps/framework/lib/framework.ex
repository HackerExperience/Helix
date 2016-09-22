defmodule HELM.Framework.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(HELF.Broker, []),
      worker(HELF.Router, [])
    ]

    opts = [strategy: :one_for_one, name: HELM.Framework.Supervisor]

    {:ok, _} = Supervisor.start_link(children, opts)
  end
end
