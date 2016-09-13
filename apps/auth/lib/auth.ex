require IEx

defmodule HELM.Auth.App do
  use Application

  alias HELM.Auth

  def start(_type, _args) do
    # Import helpers for defining supervisors
    import Supervisor.Spec, warn: false

    # Supervise the Stack server which will be started with
    # a single argument [:hello] and the default registered
    # name of MyStack.
    children = [
      #worker(Stack, [[], [name: MyStack]])
    ]

    HeBroker.Consumer.subscribe(:auth, "jwt:create", call:
      fn _,_,id,_ ->
        Auth.JWT.generate(id)
      end)

    HeBroker.Consumer.subscribe(:auth, "jwt:verify", call:
      fn _,_,jwt,_ ->
          Auth.JWT.verify(jwt)
      end)

    # Start the supervisor with our child
    opts = [strategy: :one_for_one, name: Auth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
