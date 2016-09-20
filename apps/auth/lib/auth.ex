defmodule HELM.Auth.App do
  use Application

  alias HELM.Auth

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Auth.Service, [])
    ]

    opts = [strategy: :one_for_one, name: Auth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
