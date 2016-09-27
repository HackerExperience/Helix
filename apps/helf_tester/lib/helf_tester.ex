defmodule HELFTester.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(HELFTester, []),
    ]

    opts = [strategy: :one_for_one, name: HELFTester.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
