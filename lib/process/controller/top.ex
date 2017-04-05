defmodule Helix.Process.Controller.TableOfProcesses do
  @moduledoc """
  `TableOfProcesses` is responsible for handling the timed execution of in-game
  processes and the in-game resource allocation to those in-game processes
  """

  use GenServer

  require Logger

  alias Helix.Event
  alias Helix.Process.Repo
  alias Helix.Process.Controller.TableOfProcesses.ServerResources
  alias Helix.Process.Controller.TableOfProcesses.Allocator.Plan
  alias Helix.Process.Model.Process, as: ProcessModel
  alias Helix.Process.Model.Process.Resources
  alias Helix.Process.Model.Process.ProcessType
  alias Helix.Process.Service.Local.Top.Manager

  import HELL.MacroHelpers

  defstruct [:server_id, :processes, :resources, :timer, :broker]

  @type server_id :: String.t
  @type timer :: {DateTime.t, tref :: reference} | nil

  # 3 minutes to hibernate the process
  @hibernate_after 3 * 60 * 1_000

  @spec start_link(server_id) :: GenServer.on_start
  @doc """
  Starts a process to hold the state of a _Table Of Processes_
  """
  def start_link(server_id, params \\ []),
    do: GenServer.start_link(__MODULE__, {server_id, params})

  @spec priority(pid, ProcessModel.id, 0..5) :: :ok
  @doc """
  Changes the priority of an in-game process
  """
  def priority(pid, process_id, value) when value in 0..5,
    do: GenServer.cast(pid, {:priority, process_id, value})

  @spec pause(pid, ProcessModel.id) :: :ok
  @doc """
  Pauses an in-game process
  """
  def pause(pid, process_id),
    do: GenServer.cast(pid, {:pause, process_id})

  @spec resume(pid, ProcessModel.id) :: :ok | {:error, reason :: term}
  @doc """
  Resumes an in-game process
  """
  def resume(pid, process_id),
    do: GenServer.call(pid, {:resume, process_id})

  @spec kill(pid, ProcessModel.id) :: :ok
  @doc """
  Kills an in-game process
  """
  def kill(pid, process_id),
    do: GenServer.cast(pid, {:kill, process_id})

  @spec state(pid) :: %__MODULE__{}
  @doc false
  def state(pid),
    do: GenServer.call(pid, :state)

  @spec resources(
    pid,
    %{cpu: integer, ram: integer, dlk: integer, ulk: integer}) :: :ok
  @doc false
  def resources(pid, resources),
    do: GenServer.cast(pid, {:resources, resources})

  @spec apply_update(term) :: [ProcessModel.t]
  docp """
  Asynchronously stores the changes from `changeset_list` into the database and
  immediately returns all the changesets applied as models

  Note that the database update function might fail
  """
  defp apply_update(input) do
    # FIXME: This interface is pure garbage
    {changeset_list, deleted_list} = case input do
      {:update_and_delete, changeset, deleted} ->
        {changeset, deleted}
      changeset_list when is_list(changeset_list) ->
        {changeset_list, []}
    end

    spawn fn ->
      Repo.transaction fn ->
        Enum.each(changeset_list, &Repo.update/1)
        Enum.each(deleted_list, &Repo.delete/1)
      end
    end

    # Returns the processes that are still "running"
    Enum.map(changeset_list, &Ecto.Changeset.apply_changes/1)
  end

  @spec request_server_resources(server_id) ::
    {:ok, ServerResources.t}
    | {:error, reason :: term}
  docp """
  Requests the amount of in-game hardware related to the `server_id` server
  """
  defp request_server_resources(server) do
    # FIXME
    alias Helix.Hardware.Controller.Component
    alias Helix.Hardware.Controller.Motherboard
    alias Helix.Server.Controller.Server

    with \
      %{motherboard_id: motherboard} <- Server.fetch(server),
      true <- not is_nil(motherboard) || :server_not_assembled,
      component = %{} <- Component.fetch(motherboard),
      motherboard = %{} <- Motherboard.fetch!(component),
      resources = %{} <- Motherboard.resources(motherboard)
    do
      resources = ServerResources.cast(resources)
      {:ok, resources}
    else
      reason ->
        {:error, reason}
    end
  end

  @spec request_server_processes(server_id) :: {:ok, [ProcessModel.t]}
  docp """
  Fetches the list of in-game processes running on this server
  """
  defp request_server_processes(server_id) do
    processes =
      ProcessModel
      |> ProcessModel.Query.from_server(server_id)
      |> Repo.all()
      |> Enum.map(&ProcessModel.estimate_conclusion/1)

    {:ok, processes}
  end

  @spec notify(ProcessModel.t, :completed) :: :ok
  defp notify(process, circumstance) do
    process.process_data
    |> ProcessType.event(process, circumstance)
    |> List.wrap()
    |> Enum.each(&Event.emit/1)
  end

  @doc false
  def init({server_id, params}) do
    broker = Keyword.get(params, :broker, HELF.Broker)

    with \
      {:ok, resources} <- request_server_resources(server_id),
      {:ok, process_list} <- request_server_processes(server_id)
    do
      processes =
        process_list
        |> calculate_work()
        |> allocate(resources)
        |> apply_update()

      state = %__MODULE__{
        processes: processes,
        resources: resources,
        server_id: server_id,
        timer: update_timer(processes, nil),
        broker: broker
      }

      # TODO: enqueue request to fetch the "minimum" of each process

      Manager.put(server_id, self())

      {:ok, state, @hibernate_after}
    else
      {:error, reason} ->
        {:stop, reason}
    end
  end

  @doc false
  def handle_cast({:pause, process_id}, state) do
    p2 =
      state.processes
      |> update_one(process_id, state.resources, &ProcessModel.pause/1)
      |> apply_update()

    timer = update_timer(p2, state.timer)

    {:noreply, %{state| processes: p2, timer: timer}, @hibernate_after}
  end

  def handle_cast({:priority, process_id, value}, state) do
    mapper = &ProcessModel.update_changeset(&1, %{priority: value})

    p2 =
      state.processes
      |> update_one(process_id, state.resources, mapper)
      |> apply_update()

    timer = update_timer(p2, state.timer)

    {:noreply, %{state| processes: p2, timer: timer}, @hibernate_after}
  end

  def handle_cast({:kill, process_id}, state) do
    p2 = Enum.reject(state.processes, &(&1.process_id == process_id))

    handle_info(:allocate, %{state| processes: p2})
  end

  def handle_cast({:resources, resources}, state) do
    handle_info(:allocate, %{state| resources: ServerResources.cast(resources)})
  end

  @doc false
  def handle_call({:resume, process_id}, _, state) do
    state.processes
    |> update_one(process_id, state.resources, &ProcessModel.resume/1)
    |> case do
      {:error, :insufficient_resources} ->
        {:reply, {:error, :insufficient_resources}, state, @hibernate_after}

      changeset_list when is_list(changeset_list) ->
        processes = apply_update(changeset_list)
        timer = update_timer(processes, state.timer)

        state2 = %{state| processes: processes, timer: timer}

        {:reply, :ok, state2, @hibernate_after}
    end
  end

  def handle_call(:state, _, state),
    do: {:reply, state, state, @hibernate_after}

  @doc false
  def handle_info(:allocate, state) do
    # REVIEW: I don't like the code of this handler but the choice of using
    #   partition, each, map, filter & append instead of a simple reduction is
    #   to (try to) make it easier for our contributors to understand how we
    #   handle the completion of a process

    {complete, running} =
      state.processes
      |> calculate_work()
      |> Enum.split_with(&ProcessModel.complete?/1)

    Enum.each(complete, &notify(&1, :completed))

    processes =
      complete
      # REVIEW: I don't like the idea of this function returning
      #   nil | ProcessModel.t
      |> Enum.map(&ProcessModel.handle_complete/1)
      |> Enum.reject(&is_nil/1)
      |> Kernel.++(running)
      |> allocate_dropping(state.resources)
      |> apply_update()

    state2 = %{state|
      processes: processes,
      timer: update_timer(processes, state.timer)}

    {:noreply, state2, @hibernate_after}
  end

  # Called to initiate the hibernation sequence
  def handle_info(:timeout, state = %__MODULE__{timer: nil}) do
    # No process is going to be complete soon, so we can safely shutdown this
    # server
    {:stop, :normal, state}
  end

  def handle_info(:timeout, state = %__MODULE__{timer: {moment, _}}) do
    # There is a process near it's conclusion phase, thus we should stay alive
    # (but we might hibernate if it will still take too much time)

    seconds_to_finish = Timex.diff(Timex.now(), moment, :seconds)
    if seconds_to_finish > div(@hibernate_after, 1_000) do
      {:noreply, state, :hibernate}
    else
      {:noreply, state, @hibernate_after}
    end
  end

  def handle_info(msg, state) do
    Logger.warn """
      TOP process for server_id "#{state.server_id}" received unexpected message.
      Received message:
      #{inspect msg}
    """

    {:noreply, state, @hibernate_after}
  end

  @spec update_one([ProcessModel.t], ProcessModel.id, ServerResources.t, ((Ecto.Changeset.t) -> Ecto.Changeset.t)) ::
    [Ecto.Changeset.t]
    | {:error, :insufficient_resources}
  docp """
  Updates process with `process_id` from `processes` using `mapper`
  """
  defp update_one(processes, process_id, resources, mapper) do
    processes
    |> calculate_work()
    |> Enum.map(fn p ->
      Ecto.Changeset.get_field(p, :process_id) === process_id
      && mapper.(p)
      || p
    end)
    |> allocate(resources)
  end

  @spec calculate_work([ProcessModel.t]) :: [Ecto.Changeset.t]
  defp calculate_work(process_list) do
    now = DateTime.utc_now()

    Enum.map(process_list, &ProcessModel.calculate_work(&1, now))
  end

  defp allocate(processes, resources),
    do: Plan.allocate(processes, resources)

  @spec allocate_dropping(
    [ProcessModel.t],
    Resources.t) :: {:update_and_delete, [Ecto.Changeset.t], [ProcessModel.t]}
  docp """
  Tries to allocate `resources` into `processes` and will drop randomly as many
  `processes` as needed to fit
  """
  defp allocate_dropping(processes, resources) do
    # Keeps randomly dropping processes from the TOP until the server can handle
    # the load
    processes
    |> Enum.shuffle()
    |> allocate_dropping(resources, [])
  end

  defp allocate_dropping(p = [h| t], resources, acc) do
    case allocate(p, resources) do
      {:error, :insufficient_resources} ->
        allocate_dropping(t, resources, [h| acc])
      changeset_list ->
        {:update_and_delete, changeset_list, acc}
    end
  end
  defp allocate_dropping([], _, acc),
    do: {:update_and_delete, [], acc}

  @spec update_timer([ProcessModel.t], timer) :: timer
  docp """
  Traverses the table of process and updates the timer to notify the process
  when the next estimated change will happen.
  """
  defp update_timer(processes, timer) do
    stop_timer(timer)

    processes
    |> Enum.map(&ProcessModel.seconds_to_change/1)
    |> Enum.reduce(nil, &min/2)
    |> start_timer()
  end

  @spec start_timer(non_neg_integer | nil) :: timer
  defp start_timer(nil),
    do: nil
  defp start_timer(seconds) do
    date = Timex.shift(DateTime.utc_now(), seconds: seconds)
    tref = :erlang.send_after(seconds * 1_000, self(), :allocate)

    {date, tref}
  end

  @spec stop_timer(timer) :: any
  defp stop_timer(nil),
    do: nil
  defp stop_timer({_, tref}),
    do: :erlang.cancel_timer(tref, async: true, info: false)
end
