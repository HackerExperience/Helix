defmodule Helix.Process.Service.Local.TOP.Domain do
  @moduledoc false

  alias Ecto.Changeset
  alias Helix.Process.Controller.TableOfProcesses.Allocator.Plan
  alias Helix.Process.Controller.TableOfProcesses.ServerResources
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Process.ProcessType

  @behaviour :gen_statem

  @typep t :: %__MODULE__{}
  @type server_id :: HELL.PK.t
  @type process_id :: HELL.PK.t
  @type process :: Process.t | Changeset.t
  @type resources :: ServerResources.t

  # gen_statem instruction to execute procedure to flush instructions to the
  # handler
  @flush {:next_event, :internal, :flush}

  # gen_statem instruction to execute procedure to allocate resources into
  # processes
  @allocate {:next_event, :internal, :allocate}

  @enforce_keys [:gateway, :processes, :resources, :handler]
  defstruct [
    gateway: nil,
    processes: nil,
    resources: nil,
    instructions: [],
    handler: nil
  ]

  @spec start_link(server_id, [process], resources) ::
    {:ok, pid}
    | :ignore
    | {:error, :badarg}
  def start_link(gateway, processes, resources) do
    handler = self()
    init_options = {gateway, processes, resources, handler}
    :gen_statem.start_link(__MODULE__, init_options, [])
  end

  @spec priority(pid, process_id, 0..5) ::
    :ok
  def priority(pid, process, priority) when priority in 0..5,
    do: :gen_statem.cast(pid, {:priority, process, priority})

  @spec pause(pid, process_id) ::
    :ok
  def pause(pid, process),
    do: :gen_statem.cast(pid, {:pause, process})

  @spec resume(pid, process_id) ::
    :ok
  def resume(pid, process),
    do: :gen_statem.cast(pid, {:resume, process})

  @spec kill(pid, process_id) ::
    :ok
  def kill(pid, process),
    do: :gen_statem.cast(pid, {:kill, process})

  @spec reset(pid, [process], resources) ::
    :ok
  def reset(pid, processes, resources),
    do: :gen_statem.cast(pid, {:reset, processes, resources})

  @doc false
  def init({gateway, processes, resources, handler}) do
    data = %__MODULE__{
      gateway: gateway,
      processes: processes,
      resources: resources,
      handler: handler
    }

    actions = [@allocate]

    {:ok, :startup, data, actions}
  end

  @doc false
  def callback_mode,
    do: :handle_event_function

  @doc false
  def code_change(_vsn, state, data, _extra) do
    {:ok, state, data}
  end

  @doc false
  def terminate(_reason, _state, _data) do
    :top
  end

  @doc false
  def handle_event(event_type, event_msg, state, data)

  # This callback exists because i intend to potentially include additional
  # operations on startup
  def handle_event(:internal, :allocate, :startup, data) do
    actions = [@allocate]

    {:next_state, :running, data, actions}
  end

  def handle_event(:internal, :allocate, :running, data) do
    now = DateTime.utc_now()

    {data, processes} =
      Enum.reduce(data.processes, {data, []}, fn
        p = %Changeset{action: :delete}, {data_acc, process_acc} ->
          data_acc = store_processes(data_acc, [p])
          {data_acc, process_acc}
        process, {data_acc, process_acc} ->
          process = Process.calculate_work(process, now)

          if Process.complete?(process) do
            # TODO: this is an awkward interface. Wrap into into a facade maybe?
            process_data = Changeset.get_field(process, :process_data)
            {processes, events} = ProcessType.conclusion(
              process_data,
              process)

            # I think i should probably make this a function of the event module
            process_conclusion = %Process.ProcessConclusionEvent{
              gateway_id: Changeset.get_field(process, :gateway_id),
              target_id: Changeset.get_field(process, :target_server_id)
            }

            {delete, keep} =
              processes
              |> List.wrap()
              |> Enum.split_with(fn
                %Changeset{action: :delete} ->
                  true
                _ ->
                  false
              end)

            data_acc =
              data_acc
              |> store_processes(delete)
              |> store_events([process_conclusion])
              |> store_events(events)

            {data_acc, keep ++ process_acc}
          else
            {data_acc, [process| process_acc]}
          end
      end)

    processes = allocate(processes, data.resources)

    newdata = store_processes(%{data| processes: []}, processes)

    time =
      processes
      |> Enum.map(&Process.seconds_to_change/1)
      |> Enum.reduce(:infinity, &min/2)

    notify_completed = {:timeout, time, :completed}
    actions = [notify_completed]

    {:keep_state, newdata, actions}
  end

  # Sends a set of instructions to the handler process to persist data
  def handle_event(:internal, :flush, :running, data) do
    with instructions = [_|_] <- :lists.reverse(data.instructions) do
      send(data.handler, {:top, :instructions, instructions})
    end

    {:keep_state, %{data| instructions: []}}
  end

  # Changes the priority of a single process
  def handle_event(:cast, {:priority, id, priority}, :running, data) do
    processes =
      data.processes
      |> calculate_worked()
      |> Enum.map(fn p ->
        Changeset.get_field(p, :process_id) == id
        && Process.update_changeset(p, %{priority: priority})
        || p
      end)

    actions = [@allocate, @flush]
    {:keep_state, %{data| processes: processes}, actions}
  end

  # Pauses a single process
  def handle_event(:cast, {:pause, id}, :running, data) do
    processes =
      data.processes
      |> calculate_worked()
      |> Enum.map(fn p ->
        Changeset.get_field(p, :process_id) == id
        && Process.pause(p)
        || p
      end)

    actions = [@allocate, @flush]
    {:keep_state, %{data| processes: processes}, actions}
  end

  # Resumes a single process
  def handle_event(:cast, {:resume, id}, :running, data) do
    # TODO: block this action if it would trigger "resource overflow"
    processes =
      data.processes
      |> calculate_worked()
      |> Enum.map(fn p ->
        Changeset.get_field(p, :process_id) == id
        && Process.resume(p)
        || p
      end)

    actions = [@allocate, @flush]
    {:keep_state, %{data| processes: processes}, actions}
  end

  # Kills a single process
  def handle_event(:cast, {:kill, id}, :running, data) do
    # Marks the process to be removed. It'll be included in the remove
    # instructions after the allocation procedure
    processes = Enum.map(data.processes, fn
      p = %{process_id: ^id} ->
        %{Changeset.change(p)| action: :delete}
      p ->
        p
    end)

    actions = [@allocate, @flush]
    {:keep_state, %{data| processes: processes}, actions}
  end

  # Resets the machine (useful as a recovery mechanism for when the persisted
  # state is inconsistent with current state)
  def handle_event(:cast, {:reset, processes, resources}, :running, data) do
    new_data = %{
      data|
        instructions: [],
        processes: processes,
        resources: resources
    }

    actions = [@allocate]

    {:next_state, :startup, new_data, actions}
  end

  # Cleans processes so the in-game server can be shutdown gracefully
  def handle_event({:call, from}, :shutdown, :running, data) do
    # Deallocates resources completely, so the processes can be "frozen" while
    # the server is shutdown
    processes =
      data.processes
      |> calculate_worked()
      |> Enum.map(&Process.update_changeset(&1, %{allocated: %{}}))

    new_data = store_processes(data, processes)

    reply = {:reply, from, new_data.instructions}

    # This timeout is executed if the handler for some reason fails to execute
    # it's operation in a timely manner, effectively making the whole shutdown
    # sequence to fail
    kill_timer = {:timeout, 10_000, :timeout}

    # Will move the process state to the shutdown state so it can wait for the
    # handler to properly
    {:next_state, :shutdown, nil, [reply, kill_timer]}
  end

  # This event means that for some reason the graceful shutdown didn't happen in
  # a timely manner, so this will force a shutdown (and cause the supervisor to
  # reset both this state machine and the handler)
  def handle_event(:internal, :timeout, :shutdown, _) do
    {:stop, :shutdown_failed}
  end

  @spec calculate_worked([Process.t | Changeset.t]) ::
    [Changeset.t]
  defp calculate_worked(processes) do
    now = DateTime.utc_now()

    Enum.map(processes, &Process.calculate_work(&1, now))
  end

  @spec allocate_minimum([Process.t]) ::
    {[Changeset.t], resources}
  defp allocate_minimum(processes) do
    Enum.map_reduce(processes, %ServerResources{}, fn
      cs = %Changeset{action: :delete}, acc ->
        {cs, acc}
      process, acc ->
        process = Process.allocate_minimum(process)
        acc = ServerResources.sum_process(acc, process)

        {process, acc}
    end)
  end

  @spec allocate([Process.t | Changeset.t], resources) ::
    [Changeset.t]
  defp allocate(processes, resources) do
    {processes, reserved_resources} = allocate_minimum(processes)

    # Subtracts from the total resource pool the amount that was already
    # reserved by the processes
    remaining_resources = ServerResources.sub(resources, reserved_resources)

    {processes, resources} =
      case ServerResources.negatives(remaining_resources) do
        [] ->
          {processes, remaining_resources}
        negative_resources ->
          # If the server doesn't have enough resources to keep the instanciated
          # processes, run a procedure to free the minimum possible resources by
          # killing the most consuming processes that are over-reserving those
          # resources
          {dropped, freed_resources} =
            drop_processes_to_free_resources(processes, negative_resources)

          processes = Enum.map(processes, fn changeset ->
            id = Changeset.get_field(changeset, :process_id)

            if MapSet.member?(dropped, id) do
              %{changeset| action: :delete}
            else
              changeset
            end
          end)

          resources = ServerResources.sum(remaining_resources, freed_resources)
          {processes, resources}
      end

    # This is necessary because our allocator is dumb and would allocate to
    # deleted processes. This will be removed in the future tho
    {remove, allocate} = Enum.split_with(processes, &(&1.action == :delete))

    remove ++ Plan.allocate(allocate, resources)
  end

  @spec drop_processes_to_free_resources([Changeset.t], list) ::
    {dropped_process_ids :: MapSet.t, freed_resources :: resources}
  defp drop_processes_to_free_resources(processes, negative_resources) do
    processes = Enum.filter_map(
      processes,
      &(&1.action != :delete),
      &Changeset.apply_changes/1)

    free_resources(
      processes,
      MapSet.new(),
      %ServerResources{},
      negative_resources)
  end

  @spec free_resources([Process.t], removed, freed, list) ::
    {removed, freed} when removed: MapSet.t, freed: ServerResources.t
  # This looks a bit complex. I'll have to think another way to make it simpler
  # without making it long and bothersome
  # This function will, for each negative_resource, remove processes that
  # consume the highest chunks of it. Then it frees the resources that
  # the removed process reserved beforehand.
  defp free_resources(processes, removed, freed, [negative_resource| t]) do
    remove_process = fn process, removed, freed ->
      removed = MapSet.put(removed, process.process_id)
      freed = ServerResources.sum_process(freed, process)
      {removed, freed}
    end

    # Since this function is called for every negative resource and a removed
    # process might have freed the resource we're querying, we have to update it
    negative_resource = {resource, _} = case negative_resource do
      {net_resource, {network_id, value}} when net_resource in [:dlk, :ulk] ->
        freed_resource = freed.net[network_id][net_resource] || 0
        {net_resource, {network_id, value - freed_resource}}
      {resource, value} when resource in [:cpu, :ram] ->
        freed_resource = freed[resource]
        {resource, value - freed_resource}
    end

    {processes, removed, freed, _} =
      processes
      |> Enum.sort_by(&(&1.allocated[resource]), &>=/2)
      |> Enum.reduce({[], removed, freed, negative_resource}, fn
        # Too much ulk or dlk used on network `n` and this is one of the main
        # wasters
        p = %{network_id: n}, {acc, removed, freed, {net_resource, {n, value}}}
        when value > 0 and net_resource in [:ulk, :dlk] ->
          {removed, freed} = remove_process.(p, removed, freed)
          freed_value = p.allocated[net_resource]
          {acc, removed, freed, {net_resource, n, value - freed_value}}

        # Too much ram or cpu consumed and this is one of the main wasters
        p, {acc, removed, freed, {resource, value}}
        when value > 0 and resource in [:cpu, :ram] ->
          {removed, freed} = remove_process.(p, removed, freed)
          freed_value = p.allocated[resource]
          {acc, removed, freed, {resource, value - freed_value}}

        # Process is not consuming the resource or the lack was of the resource
        # was already addressed
        p, {acc, removed, freed, query} ->
          {[p| acc], removed, freed, query}
      end)

    free_resources(processes, removed, freed, t)
  end

  defp free_resources(_, removed, freed, []) do
    {removed, freed}
  end

  @spec store_events(t, [struct]) ::
    t
  defp store_events(data, events) do
    Enum.reduce(events, data, fn e, acc = %{instructions: i} ->
      instruction = {:event, e}

      %{acc| instructions: [instruction| i]}
    end)
  end

  @spec store_processes(t, [Process.t | Changeset.t]) ::
    t
  defp store_processes(data, processes) do
    Enum.reduce(processes, data, fn
      e = %Changeset{action: :delete}, acc = %{instructions: i} ->
        instruction = {:delete, e}

        %{acc| instructions: [instruction| i]}
      e = %Changeset{action: :update}, acc = %{processes: p, instructions: i} ->
        instruction = {:update, e}
        e = Changeset.apply_changes(e)

        %{acc| processes: [e| p], instructions: [instruction| i]}
      e = %Changeset{action: :insert}, acc = %{processes: p, instructions: i} ->
        instruction = {:create, e}
        e = Changeset.apply_changes(e)

        %{acc| processes: [e| p], instructions: [instruction| i]}
      e = %Process{}, acc = %{processes: p, instructions: i} ->
        # This case might happen if a protocol returns a new process from it's
        # conclusion and we handle it. This is what happens (will happen) with
        # virus installing
        instruction = {:create, e}

        %{acc| processes: [e| p], instructions: [instruction| i]}
    end)
  end
end
