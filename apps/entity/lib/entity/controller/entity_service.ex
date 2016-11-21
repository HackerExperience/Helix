defmodule HELM.Controller.EntityService do

  use GenServer

  alias HELF.Broker
  alias HELM.Entity.Model.Entity, as: MdlEntity
  alias HELM.Entity.Controller.Entity, as: CtrlEntity

  @spec start_link([]) :: GenServer.on_start
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :entity_service)
  end

  @spec init([]) :: {:ok, nil}
  def init(_args) do
    Broker.subscribe("event:account:created", cast: &handle_broker_cast/4)
    Broker.subscribe("entity:find", call: &handle_broker_call/4)
    {:ok, nil}
  end

  @doc false
  def handle_broker_cast(pid, "event:account:created", id, _request) do
    GenServer.call(pid, {:entity, :create, %{account_id: id}})
  end

  @doc false
  def handle_broker_call(pid, "entity:find", id, _request) do
    response = GenServer.call(pid, {:entity, :find, id})
    {:reply, response}
  end

  @spec handle_call({:entity, :create, MdlEntity.creation_params}, GenServer.from, nil) ::
    {:reply, {:ok, MdlEntity.t} | {:error, Ecto.Changeset.t}, nil}
  @spec handle_call({:entity, :find, MdlEntity.id}, GenServer.from, nil) ::
    {:reply, {:ok, MdlEntity.t} | {:error, :notfound}, nil}
  @doc false
  def handle_call({:entity, :create, params}, _from, state) do
    case CtrlEntity.create(params) do
      {:ok, entity} ->
        Broker.cast("event:entity:created", entity.entity_id)
        {:reply, {:ok, entity}, state}
      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end
  def handle_call({:entity, :find, id}, _from, state) do
    response = CtrlEntity.find(id)
    {:reply, response, state}
  end
end