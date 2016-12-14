defmodule HELM.Account.Controller.AccountService do

  use GenServer

  alias HELF.Broker
  alias HELF.Router
  alias HELM.Account.Controller.Account, as: AccountController
  alias HELM.Account.Controller.Session, as: SessionController
  alias HELM.Account.Model.Account, as: Account

  @typep state :: nil

  @spec start_link() :: GenServer.on_start
  def start_link do
    Router.register("account.create", "account:create")
    Router.register("account.login", "account:login")

    GenServer.start_link(__MODULE__, [], name: :account_service)
  end

  @spec init(any) :: {:ok, state}
  def init(_args) do
    Broker.subscribe("account:create", call: &handle_broker_call/4)
    Broker.subscribe("account:login", call: &handle_broker_call/4)
    Broker.subscribe("event:entity:created", cast: &handle_broker_cast/4)

    {:ok, nil}
  end

  @doc false
  def handle_broker_call(_pid, "account:create", _params, _request) do
    # FIXME: implement topic
    {:reply, :unimplemented}
  end
  def handle_broker_call(pid, "account:login", %{email: email, password: password}, _request) do
    response = GenServer.call(pid, {:account, :login, email, password})
    {:reply, response}
  end

  @doc false
  def handle_broker_cast(_pid, "event:entity:created", _entity_id, _request) do
    # FIXME: implement topic
  end

  @spec handle_call(
    {:account, :create, Account.creation_params},
    GenServer.from,
    state) :: {:reply, {:ok, Account.t} | {:error, Ecto.Changeset.t}, state}
  @spec handle_call(
    {:account, :login, Account.email, Account.password},
    GenServer.from,
    state) :: {:reply, {:ok, Account.id} | {:error, :notfound}, state}
  @doc false
  def handle_call({:account, :create, params}, _from, state) do
    case AccountController.create(params) do
      {:ok, account} ->
        Broker.cast("event:account:created", account.account_id)
        {:reply, {:ok, account}, state}
      error ->
        {:reply, error, state}
    end
  end
  def handle_call({:account, :login, email, password}, _from, state) do
    with \
      {:ok, account_id} <- AccountController.login(email, password),
      {:ok, token} <- SessionController.create(account_id)
    do
      {:reply, {:ok, token}, state}
    else
      error ->
        {:reply, error, state}
    end
  end
end