defmodule HELM.Account.Controller.AccountService do

  use GenServer

  alias HELM.Account.Model.Account, as: MdlAccount
  alias HELM.Account.Controller.Account, as: CtrlAccount
  alias HELM.Account.Controller.Session, as: CtrlSession
  alias HELF.Broker
  alias HELF.Router

  # TODO: Refactor this and add meaning

  @spec start_link() :: GenServer.start
  def start_link() do
    Router.register("account.create", "account:create")
    Router.register("account.login", "account:login")
    Router.register("account.get", "account:get")

    GenServer.start_link(__MODULE__, [], name: :account_service)
  end

  @spec init(_args :: []) :: {:ok, nil}
  def init(_args) do
    Broker.subscribe("account:create", call: &handle_broker_call/4)
    Broker.subscribe("account:login", call: &handle_broker_call/4)

    {:ok, nil}
  end

  @doc false
  def handle_broker_call(pid, "account:create", account, _request) do
    response = GenServer.call(pid, {:account, :create, account})
    {:reply, response}
  end

  @doc false
  def handle_broker_call(pid, "account:login", %{email: email, password: password}, _request) do
    response = GenServer.call(pid, {:account, :login, email, password})
    {:reply, response}
  end

  @spec handle_call({:account, :create, account :: MdlAccount.create_params}, GenServer.from, nil) :: {:reply, CtrlAccount.create, nil}
  @spec handle_call({:account, :login, email :: String.t, password :: String.t}, GenServer.from, nil) :: {:reply, CtrlAccount.login, nil}
  @doc false
  def handle_call({:account, :create, account}, _from, state) do
    with {:ok, account} <- CtrlAccount.create(account) do
      Broker.cast("event:account:created", account.account_id)
      {:reply, {:ok, account}, state}
    else
      error -> {:reply, error, state}
    end
  end
  def handle_call({:account, :login, email, password}, _from, state) do
    with {:ok, account_id} <- CtrlAccount.login(email, password),
         {:ok, token} <- CtrlSession.create(account_id) do
      {:reply, {:ok, token}, state}
    else
      error -> {:reply, error, state}
    end
  end
end