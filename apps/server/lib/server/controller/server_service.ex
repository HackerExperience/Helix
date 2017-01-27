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

  @doc false
  def handle_broker_call(pid, "server:create", params, _) do
    response = GenServer.call(pid, {:server, :create, params})
    {:reply, response}
  end
  def handle_broker_call(pid, "server:attach", msg, _) do
    %{server_id: id, motherboard_id: motherboard_id} = msg
    response = GenServer.call(pid, {:server, :attach, id, motherboard_id})
    {:reply, response}
  end
  def handle_broker_call(pid, "server:detach", msg, _) do
    %{server_id: id} = msg
    response = GenServer.call(pid, {:server, :detach, id})
    {:reply, response}
  end
  def handle_broker_call(pid, "server:query", msg, _) do
    %{server_id: id} = msg
    response = GenServer.call(pid, {:server, :find, id})
    {:reply, response}
  end
  def handle_broker_call(pid, "server:hardware:resources", msg, _) do
    %{server_id: id} = msg
    response = GenServer.call(pid, {:server, :resources, id})
    {:reply, response}
  end

  @doc false
  def handle_broker_cast(pid, "event:entity:created", msg, _) do
    %{entity_id: entity_id} = msg

    params = %{
      entity_id: entity_id,
      server_type: "desktop"
    }

    GenServer.call(pid, {:server, :create, params})
  end
  def handle_broker_cast(pid, "event:motherboard:setup", msg, _) do
    %{server_id: id, motherboard_id: motherboard_id} = msg
    GenServer.call(pid, {:server, :attach, id, motherboard_id})
  end

  @spec init(any) :: {:ok, state}
  @doc false
  def init(_) do
    Broker.subscribe("server:create", call: &handle_broker_call/4)
    Broker.subscribe("server:attach", call: &handle_broker_call/4)
    Broker.subscribe("server:detach", call: &handle_broker_call/4)
    Broker.subscribe("server:query", call: &handle_broker_call/4)
    Broker.subscribe("server:hardware:resources", call: &handle_broker_call/4)
    Broker.subscribe("event:entity:created", cast: &handle_broker_cast/4)
    Broker.subscribe("event:motherboard:setup", cast: &handle_broker_cast/4)

    {:ok, nil}
  end

  @spec handle_call(
    {:server, :create, Server.creation_params},
    GenServer.from,
    state) :: {:reply, {:ok, server :: term}
              | {:error, reason :: term}, state}
  @spec handle_call(
    {:server, :attach, Server.id, PK.t},
    GenServer.from,
    state) :: {:reply, :ok | :error, state}
  @spec handle_call(
    {:server, :detach, Server.id},
    GenServer.from,
    state) :: {:reply, :ok | :error, state}
  @spec handle_call(
    {:server, :resources, HELL.PK.t},
    GenServer.from,
    state) :: {:reply, {:ok, %{any => any}} | {:error, :notfound}, state}
  @doc false
  def handle_call({:server, :create, params}, _from, state) do
    case ServerController.create(params) do
      {:ok, server} ->
        msg = %{
          server_id: server.server_id,
          entity_id: params.entity_id
        }
        Broker.cast("event:server:created", msg)
        {:reply, {:ok, server}, state}
      error ->
        {:reply, error, state}
    end
  end
  def handle_call({:server, :attach, id, motherboard_id}, _from, state) do
    case ServerController.attach(id, motherboard_id) do
      {:ok, _} ->
        msg = %{
          server_id: id,
          motherboard_id: motherboard_id
        }
        Broker.cast("event:server:attached", msg)
        {:reply, :ok, state}
      {:error, _} ->
        {:reply, :error, state}
    end
  end
  def handle_call({:server, :detach, id}, _from, state) do
    case ServerController.detach(id) do
      {:ok, _} ->
        msg = %{server_id: id}
        Broker.cast("event:server:detached", msg)
        {:reply, :ok, state}
      {:error, _} ->
        {:reply, :error, state}
    end
  end
  def handle_call({:server, :find, id}, _from, state) do
    reply = ServerController.find(id)
    {:reply, reply, state}
  end
  def handle_call({:server, :resources, id}, _from, state) do
    with \
      {:ok, server} <- ServerController.find(id),
      %{motherboard_id: mib} when not is_nil(mib) <- server,
      msg = %{motherboard_id: mib},
      topic = "hardware:motherboard:resources",
      {_, {:ok, resources}} <- Broker.call(topic, msg)
    do
      {:reply, {:ok, resources}, state}
    else
      _ ->
        {:reply, {:error, :notfound}, state}
    end
  end
end