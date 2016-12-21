defmodule HELM.Server.Controller.ServerService do

  use GenServer

  alias HELF.Broker
  alias HELL.PK
  alias HELM.Server.Model.Server, as: ServerModel
  alias HELM.Server.Controller.Server, as: ServerController
  alias HELM.Server.Controller.Server, as: CtrlServers

  @typep state :: nil

  @spec start_link() :: GenServer.on_start
  def start_link do
    GenServer.start_link(__MODULE__, [], name: :server)
  end

  @spec init(any) :: {:ok, state}
  @doc false
  def init(_) do
    Broker.subscribe("event:entity:created", cast: &handle_broker_cast/4)
    Broker.subscribe("server:create", call: &handle_broker_call/4)

    Broker.subscribe("server:attach", call: &handle_broker_call/4)
    Broker.subscribe("server:detach", call: &handle_broker_call/4)
    Broker.subscribe("server:find", call: &handle_broker_call/4)

    {:ok, nil}
  end

  @spec handle_broker_cast(pid, PK.t, term, term) :: no_return
  @doc false
  def handle_broker_cast(pid, "event:entity:created", entity_id, request) do
    params = %{
      entity_id: entity_id,
      server_type: "desktop"
    }

    GenServer.call(pid, {:server, :create, params, request})
  end

  @doc false
  def handle_broker_call(pid, "server:create", params, request) do
    response = GenServer.call(pid, {:server, :create, params, request})
    {:reply, response}
  end
  def handle_broker_call(pid, "server:attach", {id, mobo}, _request) do
    response = GenServer.call(pid, {:server, :attach, id, mobo})
    {:reply, response}
  end
  def handle_broker_call(pid, "server:detach", id, _request) do
    response = GenServer.call(pid, {:server, :detach, id})
    {:reply, response}
  end
  def handle_broker_call(pid, "server:find", id, _request) do
    response = GenServer.call(pid, {:server, :find, id})
    {:reply, response}
  end

  @spec handle_call(
    {:server, :create, ServerModel.creation_params, HeBroker.Request.t},
    GenServer.from,
    state) :: {:reply, {:ok, server :: term}
              | {:error, reason :: term}, state}
  @spec handle_call(
    {:server, :attach, server :: HELL.PK.t, motherboard :: HELL.PK.t},
    GenServer.from,
    state) :: {:reply, :ok | :error, state}
  @spec handle_call(
    {:server, :detach, HELL.PK.t},
    GenServer.from,
    state) :: {:reply, :ok | :error, state}
  @doc false
  def handle_call({:server, :create, params, request}, _from, state) do
    case ServerController.create(params) do
      {:ok, server} ->
        Broker.cast("event:server:created", {server.server_id, params.entity_id}, request: request)
        {:reply, {:ok, server}, state}
      error ->
        {:reply, error, state}
    end
  end
  def handle_call({:server, :attach, id, mobo}, _from, state) do
    {status, _} = CtrlServers.attach(id, mobo)
    {:reply, status, state}
  end
  def handle_call({:server, :detach, id}, _from, state) do
    {status, _} = CtrlServers.detach(id)
    {:reply, status, state}
  end
  def handle_call({:server, :find, id}, _from, state) do
    reply = CtrlServers.find(id)
    {:reply, reply, state}
  end
end