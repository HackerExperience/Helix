defmodule Helix.Account.Controller.EntityObserver do

  use GenServer

  alias HELF.Broker
  alias HELL.PK

  @type state :: %{optional(reference) => pid}

  @spec start_link() :: GenServer.on_start
  def start_link(),
    do: GenServer.start_link(__MODULE__, [])

  @spec init(any) :: {:ok, state}
  @doc false
  def init([]) do
    Broker.subscribe("account:entity:observe", call: &handle_broker_call/4)
    Broker.subscribe("account:entity:stop-observing", call: &handle_broker_call/4)
    Broker.subscribe("event:entity:created", cast: &handle_broker_cast/4)

    {:ok, %{}}
  end

  @spec observe(HeBroker.Request.t, non_neg_integer) :: no_return
  def observe(request, timeout \\ 5_000) do
    ref = make_ref()

    Broker.call("account:entity:observe", {ref, self()}, request: request)
    Broker.cast("event:entity:create", {:account, ref}, request: request)

    receive do
      {:entity_created, ^ref, entity_id, request} ->
        Broker.call("account:entity:stop-observing", ref, request: request)
        {:ok, entity_id}
    after
      timeout ->
        Broker.call("account:entity:stop-oberving", ref, request: request)
        {:error, :timeout}
    end
  end

  @doc false
  def handle_broker_call(pid, "account:entity:observe", {ref, receiver}, _req) do
    status = GenServer.call(pid, {:observe, ref, receiver})
    {:reply, status}
  end
  def handle_broker_call(pid, "account:entity:stop-observing", ref, _req) do
    status = GenServer.call(pid, {:stop_observing, ref})
    {:reply, status}
  end

  @doc false
  def handle_broker_cast(pid, "event:entity:created", {:account, ref, entity_id}, request) do
    GenServer.cast(pid, {:receive, ref, entity_id, request})
  end

  @spec handle_call({:observe, reference, pid}, GenServer.from, state) ::
    {:reply, :ok, state}
  @spec handle_call({:stop_observing, reference}, GenServer.from, state) ::
    {:reply, :ok, state}
  @doc false
  def handle_call({:observe, ref, pid}, _from, state) do
    new_state = Map.put(state, ref, pid)
    {:reply, :ok, new_state}
  end
  def handle_call({:stop_observing, ref}, _from, state) do
    new_state = Map.delete(state, ref)
    {:reply, :ok, new_state}
  end

  @spec handle_cast(
    {:receive, reference, PK.t, HeBroker.Request.t},
    state) :: {:noreply, state}
  @doc false
  def handle_cast({:receive, ref, entity_id, request}, state) do
    case Map.fetch(state, ref) do
      {:ok, pid} ->
        send pid, {:entity_created, ref, entity_id, request}
        new_state = Map.delete(state, ref)
        {:noreply, new_state}
      _ ->
        {:noreply, state}
    end
  end
end