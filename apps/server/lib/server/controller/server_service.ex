defmodule HELM.Server.Controller.ServerService do

  use GenServer

  alias HELF.Broker
  alias HELM.Server.Controller.Server, as: CtrlServers

  @typep state :: nil

  @spec start_link() :: GenServer.on_start
  def start_link do
    GenServer.start_link(__MODULE__, [], name: :server)
  end

  @spec init(any) :: {:ok, state}
  @doc false
  def init(_) do
    # Broker.subscribe("event:entity:created", cast: &handle_broker_cast/4)
    # Broker.subscribe("server:create", call: &handle_broker_call/4)
    Broker.subscribe("server:attach", call: &handle_broker_call/4)
    Broker.subscribe("server:detach", call: &handle_broker_call/4)

    {:ok, nil}
  end

  # @spec handle_broker_cast(pid, String.t, term, term) :: no_return
  # @doc false
  # def handle_broker_cast(pid, "event:entity:created", entity_id, _request),
  #   do: GenServer.call(pid, {:server, :create, entity_id})

  @doc false
  # def handle_broker_call(pid, "server:create", entity_id, _request) do
  #   response = GenServer.call(pid, {:server, :create, entity_id})
  #   {:reply, response}
  # end
  def handle_broker_call(pid, "server:attach", {id, mobo}, _request) do
    response = GenServer.call(pid, {:server, :attach, id, mobo})
    {:reply, response}
  end
  def handle_broker_call(pid, "server:detach", id, _request) do
    response = GenServer.call(pid, {:server, :detach, id})
    {:reply, response}
  end

  # @spec handle_call(
  #   {:server, :create, HELL.PK.t},
  #   GenServer.from,
  #   state) :: {:reply, {:ok, server :: term}
  #             | {:error, reason :: term}, state}
  @spec handle_call(
    {:server, :attach, server :: HELL.PK.t, motherboard :: HELL.PK.t},
    GenServer.from,
    state) :: {:reply, :ok | :error, state}
  @spec handle_call(
    {:server, :detach, HELL.PK.t},
    GenServer.from,
    state) :: {:reply, :ok | :error, state}
  @doc false
  # def handle_call({:server, :create, entity_id}, _from, state) do
  #   return = create_server(entity_id)
  #   {:reply, return, state}
  # end
  def handle_call({:server, :attach, id, mobo}, _from, state) do
    {status, _} = CtrlServers.attach(id, mobo)
    {:reply, status, state}
  end
  def handle_call({:server, :detach, id}, _from, state) do
    {status, _} = CtrlServers.detach(id)
    {:reply, status, state}
  end

  # @spec create_server(entity :: HELL.PK.t) :: {:ok, server :: HELL.PK.t}
  #                                             | {:error, reason :: term}
  # defp create_server(entity_id) do
  #   with {:ok, server} <- CtrlServers.create(%{entity_id: entity_id}) do
  #     Broker.cast("event:server:created", server.server_id)
  #     {:ok, server.server_id}
  #   end
  # end
end