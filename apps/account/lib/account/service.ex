defmodule HELM.Account.Service do
  use GenServer

  alias HELM.Account.Controller, as: AccountCtrl
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
      fn pid,_,account,timeout ->
        response = GenServer.call(pid, {:account_create, account}, timeout)
        {:reply, response}
      end)

    {:ok, %{}}
  end

  def handle_call({:account_create, account}, _from, state) do
    response = AccountCtrl.create(account)
    {:reply, response, state}
  end
end
