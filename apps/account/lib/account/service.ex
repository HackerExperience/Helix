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
      fn pid,_,account,timeout ->
        response = GenServer.call(pid, {:account_create, account}, timeout)
        {:reply, response}
      end)

    Broker.subscribe(:account_service, "account:login", call:
      fn pid,_,account,timeout ->
        GenServer.call(pid, {:account_login, account}, timeout)
      end)

    {:ok, %{}}
  end

  def handle_call({:account_create, account}, _from, state) do
    response = Account.Controller.create(account)
    {:reply, response, state}
  end

  def handle_call({:account_login, account}, _from, state) do
    response = Account.Controller.login_with(account)
    {:reply, response, state}
  end
end
