defmodule HELM.HELFBroker.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(HELF.Broker, [])]

    opts = [strategy: :one_for_one, name: HELFBroker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end