defmodule Helix.Server.Controller.ServerService do

  use GenServer

  alias HELF.Broker
  alias HELL.PK
  alias Helix.Server.Controller.Server, as: ServerController
  alias Helix.Server.Model.Server

  @typep state :: nil

  @spec start_link() :: GenServer.on_start
  def start_link do
    GenServer.start_link(__MODULE__, [], name: :server)
  end

  @spec init(any) :: {:ok, state}
  @doc false
  def init(_) do
    Broker.subscribe("event:entity:created", cast: &handle_broker_cast/4)
    Broker.subscribe("event:motherboard:setup", cast: &handle_broker_cast/4)
    Broker.subscribe("server:create", call: &handle_broker_call/4)
    Broker.subscribe("server:attach", call: &handle_broker_call/4)
    Broker.subscribe("server:detach", call: &handle_broker_call/4)
    Broker.subscribe("server:query", call: &handle_broker_call/4)

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
  def handle_broker_cast(pid, "event:motherboard:setup", msg, req) do
    %{server_id: server_id, motherboard_id: mobo_id} = msg
    GenServer.call(pid, {:server, :attach, server_id, mobo_id, req})
  end

  @doc false
  def handle_broker_call(pid, "server:create", params, request) do
    response = GenServer.call(pid, {:server, :create, params, request})
    {:reply, response}
  end
  def handle_broker_call(pid, "server:attach", {server_id, mobo_id}, req) do
    response = GenServer.call(pid, {:server, :attach, server_id, mobo_id, req})
    {:reply, response}
  end
  def handle_broker_call(pid, "server:detach", server_id, req) do
    response = GenServer.call(pid, {:server, :detach, server_id, req})
    {:reply, response}
  end
  def handle_broker_call(pid, "server:query", id, _request) do
    response = GenServer.call(pid, {:server, :find, id})
    {:reply, response}
  end

  @spec handle_call(
    {:server, :create, Server.creation_params, HeBroker.Request.t},
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
  def handle_call({:server, :create, params, req}, _from, state) do
    case ServerController.create(params) do
      {:ok, server} ->
        # FIXME: always use maps on events
        Broker.cast("event:server:created", {server.server_id, params.entity_id}, request: req)
        {:reply, {:ok, server}, state}
      error ->
        {:reply, error, state}
    end
  end
  def handle_call({:server, :attach, server_id, mobo_id, req}, _from, state) do
    case ServerController.attach(server_id, mobo_id) do
      {:ok, _} ->
        msg = %{
          server_id: server_id,
          motherboard_id: mobo_id}
        Broker.cast("event:server:attached", msg, request: req)
        {:reply, :ok, state}
      {:error, _} ->
        {:reply, :error, state}
    end
  end
  def handle_call({:server, :detach, server_id, req}, _from, state) do
    case ServerController.detach(server_id) do
      {:ok, _} ->
        msg = %{server_id: server_id}
        Broker.cast("event:server:detached", msg, request: req)
        {:reply, :ok, state}
      {:error, _} ->
        {:reply, :error, state}
    end
  end
  def handle_call({:server, :find, id}, _from, state) do
    reply = ServerController.find(id)
    {:reply, reply, state}
  end
end