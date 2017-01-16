defmodule Helix.Process.Controller.TableOfProcesses do
  @moduledoc """
  `TableOfProcesses` is responsible for handling the timed execution of in-game
  processes and the in-game resource allocation to those in-game processes
  """

  use GenServer

  require Logger

  alias Helix.Process.Repo
  alias Helix.Process.Model.Process, as: ProcessModel
  alias Helix.Process.Model.Process.Resources
  alias Helix.Process.Model.Process.SoftwareType

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

  @spec priority(pid, ProcessModel.id, 0..5) :: no_return
  @doc """
  Changes the priority of an in-game process
  """
  def priority(pid, process_id, value) when value in 0..5,
    do: GenServer.cast(pid, {:priority, process_id, value})

  @spec pause(pid, ProcessModel.id) :: no_return
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

  @spec kill(pid, ProcessModel.id) :: no_return
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
    %{cpu: integer, ram: integer, dlk: integer, ulk: integer}) :: no_return
  @doc false
  def resources(pid, resources),
    do: GenServer.cast(pid, {:resources, resources})

  @spec apply_update([Ecto.Changeset.t]) :: ProcessModel.t
  @spec apply_update(
    {:update_and_delete, [Ecto.Changeset.t], [ProcessModel.t]}) :: ProcessModel.t
  docp """
  Asynchronously stores the changes from `changeset_list` into the database and
  immediately returns all the changesets applied as models

  Note that the database update function might fail
  """
  defp apply_update(input) do
    {changeset_list, deleted_list} = case input do
      {:update_and_delete, changeset, deleted} ->
        {changeset, deleted}
      changeset_list when is_list(changeset_list) ->
        {changeset_list, []}
    end

    spawn fn ->
      Repo.transaction fn ->
        Enum.each(changeset_list, &Repo.update!/1)
        Enum.each(deleted_list, &Repo.delete/1)
      end
    end

    Enum.map(changeset_list, &Ecto.Changeset.apply_changes/1)
  end

  @spec request_server_resources(module, server_id) :: {:ok, Resources.t} | {:error, reason :: term}
  docp """
  Requests the amount of in-game hardware related to the `server_id` server
  """
  defp request_server_resources(broker, server_id) do
    with \
      params = %{server_id: server_id},
      {_, {:ok, return}} <- broker.call("server:hardware:resources:get", params)
    do
      Resources.from_server_resources(return)
    end
  end

  @spec request_server_processes(module, server_id) :: {:ok, [ProcessModel.t]} | {:error, reason :: term}
  docp """
  Requests the list of in-game processes running on this server

  Does so by querying the Server service, receiving the list of process id's
  that the server has and then fetching them from database
  """
  defp request_server_processes(broker, server_id) do
    with \
      params = %{server_id: server_id},
      {_, {:ok, process_list}} <- broker.call("server:processes:get", params)
    do
      processes =
        ProcessModel
        |> ProcessModel.from_list(process_list)
        |> Repo.all()
        |> Enum.map(&ProcessModel.estimate_conclusion/1)

      {:ok, processes}
    end
  end

  @spec notify(module, ProcessModel.t, atom) :: no_return
  defp notify(broker, process, :complete) do
    namespace = SoftwareType.event_namespace(process.software)
    message = %{
      process_id: process.process_id,
      target_server_id: process.target_server_id,
      software: process.software
    }

    # Should become something like 'event:process:cracker:completed'
    topic = namespace <> ":completed"

    broker.cast(topic, message)
  end

  @doc false
  def init({server_id, params}) do
    broker = Keyword.get(params, :broker, HELF.Broker)

    with \
      {:ok, resources} <- request_server_resources(broker, server_id),
      {:ok, process_list} <- request_server_processes(broker, server_id)
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

      {:ok, state, @hibernate_after}
    else
      {:error, reason} ->
        {:stop, reason}
      _ ->
        {:stop, "unexpected error"}
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
    {:ok, r2} = Resources.from_server_resources(resources)

    handle_info(:allocate, %{state| resources: r2})
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

    Enum.each(complete, &notify(state.broker, &1, :complete))

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

    if Timex.now() |> Timex.diff(moment, :seconds) > div(@hibernate_after, 1_000) do
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

  @spec update_one(
    [ProcessModel.t],
    ProcessModel.id,
    Resources.t,
    ((Ecto.Changeset.t) -> Ecto.Changeset.t)) ::
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

  @spec allocate([ProcessModel.t], Resources.t) :: [Ecto.Changeset.t]
  docp """
  Allocates dynamic resources to the `processes` as long as the total does not
  exceed `resources`
  """
  defp allocate(processes, resources) do
    processes = Enum.map(processes, &ProcessModel.allocate_minimum/1)

    allocated = Enum.reduce(processes, %Resources{}, fn p, acc ->
      Resources.sum(acc, Ecto.Changeset.get_field(p, :allocated))
    end)

    free = Resources.sub(resources, allocated)

    shares =
      processes
      |> Enum.map(&ProcessModel.allocation_shares/1)
      |> Enum.sum()

    if :lt == Resources.compare(resources, allocated) do
      # When the minimum allocation of the process list is bigger
      {:error, :insufficient_resources}
    else
      allocate(processes, free, shares, [])
    end
  end

  @spec allocate(
    [ProcessModel.t],
    Resources.t,
    shares :: non_neg_integer,
    [ProcessModel.t]) :: [Ecto.Changeset.t]
  defp allocate([], _, _, acc),
    do: acc
  defp allocate(processes, _, 0, acc),
    do: processes ++ acc
  defp allocate(processes, resources, shares, acc) do
    # FIXME: tried to make it a bit more obvious but it's still a tadbit
    #   impossible to understand how the allocation works without me explaining
    #   (so it means that it's still smelly code)

    # How many resources can be
    share = Resources.div(resources, shares)

    allocated_processes =
      processes
      |> Enum.map(&Resources.mul(share, &1.priority))
      |> Enum.zip(processes)
      |> Enum.map(fn {a, p} -> ProcessModel.allocate(p, a) end)

    filter = fn {p2, p1} ->
      p2 !== p1 and ProcessModel.can_allocate?(p2)
    end

    zipped = Enum.zip(allocated_processes, processes)

    # A group_by is used instead of a partition here because group_by allow
    # 1-pass mapping
    %{false: nalloc, true: realloc} = Enum.group_by(zipped, filter, &elem(&1, 0))

    # How many shares should the rest of resources be divided by for the next
    # allocation round
    s2 = realloc |> Enum.map(&(&1.priority)) |> Enum.sum()

    # How much resource was allocated on this round
    r_delta =
      zipped
      |> Enum.map(fn {p2, p1} -> Resources.sub(p2.allocated, p1.allocated) end)
      |> Enum.reduce(&Resources.sum/2)

    # How many resources are left for next round
    r2 = Resources.sub(resources, r_delta)

    allocate(realloc, r2, s2, nalloc ++ acc)
  end

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
  defp update_timer([], timer),
    do: stop_timer(timer)
  defp update_timer(processes, timer) do
    stop_timer(timer)

    processes
    |> Enum.map(&ProcessModel.seconds_to_change/1)
    |> Enum.reduce(&min/2)
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

  @spec stop_timer(timer) :: no_return
  defp stop_timer(nil),
    do: nil
  defp stop_timer({_, tref}),
    do: :erlang.cancel_timer(tref, async: true, info: false)
end