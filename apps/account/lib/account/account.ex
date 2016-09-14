defmodule HELM.Account.Service do
  use GenServer

  alias HELM.Account
  alias HeBroker.Consumer

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :account_service)
  end

  def init(_args) do
    Consumer.subscribe(:account_service, "account:create", call:
      fn _,_,account,_ ->
        response = Account.Controller.new_account(account)
        {:reply, response}
      end)

    Consumer.subscribe(:account_service, "account:get", call:
      fn _,_,request,_ ->
        Account.Controller.get(request)
      end)

    Consumer.subscribe(:account_service, "account:login", call:
      fn _,_,account,_ ->
        response = Account.Controller.login_with(account)
        {:reply, response}
      end)

    # TODO: fix this return
    {:ok, %{}}
  end

end
