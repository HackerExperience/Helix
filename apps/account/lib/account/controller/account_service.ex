defmodule HELM.Account.Controller.AccountService do

  use GenServer

  alias HELM.Account.Controller.Account, as: CtrlAccount
  alias HELF.Broker
  alias HELF.Router

  # TODO: Refactor this and add meaning

  def start_link(state \\ []) do
    Router.register("account.create", "account:create")
    Router.register("account.login", "account:login")
    Router.register("account.get", "account:get")

    GenServer.start_link(__MODULE__, state, name: :account_service)
  end

  def init(_args) do
    Broker.subscribe("account:create", call: &handle_broker_call/4)
    Broker.subscribe("account:login", call: &handle_broker_call/4)

    {:ok, nil}
  end

  @doc false
  def handle_broker_call(pid, "account:login", params, _request) do
    response = GenServer.call(pid, {:account, :login, params})
    {:reply, response}
  end

  @doc false
  def handle_broker_call(pid, "account:create", account, _request) do
    response = GenServer.call(pid, {:account, :create, account})
    {:reply, response}
  end

  @doc false
  def handle_call({:account, :create, account}, _from, state) do
    with {:ok, account} <- CtrlAccount.create(account) do
      Broker.cast("event:account:created", account.account_id)
      {:reply, {:ok, account}, state}
    else
      error -> {:reply, error, state}
    end
  end

  @doc false
  def handle_call({:account, :login, %{email: email, password: password}}, _from, state) do
    with {:ok, account_id} <- CtrlAccount.login(email, password),
         {_, {:ok, token}} <- Broker.call("auth:create", account_id) do
      {:reply, {:ok, token}, state}
    else
      error -> {:reply, error, state}
    end
  end
end