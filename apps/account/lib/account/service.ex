defmodule HELM.Account.Service do
  use GenServer

  alias HELM.Account

  alias HELF.Broker
  alias HELF.Router

  def start_link(state \\ []) do
    Router.register("account.create", "account:create")
    Router.register("account.login", "account:login")
    Router.register("account.get", "account:get")

    GenServer.start_link(__MODULE__, state, name: :account_service)
  end

  def init(_args) do
    Broker.subscribe(:account_service, "account:create", call:
      fn _,_,account,_ ->
        response = Account.Controller.new_account(account)
        {:reply, response}
      end)

    Broker.subscribe(:account_service, "account:get", call:
      fn _,_,request,_ ->
        response = Account.Controller.get(request)
        {:reply, response}
      end)

    Broker.subscribe(:account_service, "account:login", call:
      fn _,_,account,_ ->
        response = Account.Controller.login_with(account)
        {:reply, response}
      end)

    # TODO: fix this return
    {:ok, %{}}
  end

end
