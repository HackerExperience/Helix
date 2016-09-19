defmodule HELM.Entity.App do
  use Application

  alias HeBroker.Consumer

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Entity.Worker.start_link(arg1, arg2, arg3)
      # worker(Entity.Worker, [arg1, arg2, arg3]),
      supervisor(HELM.Entity.Repo, [])
    ]

    Consumer.subscribe(:entity, "event:account:created", cast:
    fn _, _, id ->
      HELM.Entity.Controller.create(%{ account_id: id })
    end)

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HELM.Entity.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
