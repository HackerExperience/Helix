defmodule HELM.Account.Controller.AccountService do

  use GenServer

  alias HELM.Account.Controller.Accounts, as: CtrlAccounts
  alias HELF.Broker
  alias HELF.Router

  # TODO: Refactor this and add meaning

  def start_link(state \\ []) do
    Router.register("account.create", "account:create")
    Router.register("account.login", "account:login")
    Router.register("account.get", "account:get")

    GenServer.start_link(__MODULE__, state, name: :account_service)
  end

  @doc false
  def handle_broker_call(pid, "account:create", account, _request) do
    response = GenServer.call(pid, {:account, :create, account})
    {:reply, response}
  end

  def init(_args) do
    Broker.subscribe("account:create", call: &handle_broker_call/4)

    {:ok, nil}
  end

  def handle_call({:account, :create, account}, _from, state) do
    response = CtrlAccounts.create(account)
    {:reply, response, state}
  end
end