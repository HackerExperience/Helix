defmodule Helix.Process.Model.TOP.Allocator do

  alias Helix.Server.Model.Server
  alias Helix.Process.Model.Process

  @type shares :: number

  @spec identify_origin(Server.id, [Process.t]) ::
    [Process.t]
  defp identify_origin(server_id, processes) do
    Enum.map(processes, fn process ->
      local? =
        if process.target_id == server_id do
          false
        else
          true
        end

      %{process| local?: local?}
    end)
  end

  @type allocated_process :: {Process.t | term, Process.Resources.t | term}

  @type allocation_successful ::
    %{
      dropped: [Process.t],
      allocated: [Process.t]
    }

  @type allocation_failed ::
    {:error, :resources, [Process.t]}

  @type allocation_result ::
    {:ok, allocation_successful}
    | allocation_failed

  @spec allocate(Server.id, Process.Resources.t, [Process.t], opts :: term) ::
    allocation_result
  def allocate(server_id, total_resources, processes, _opts \\ []) do
    # forced_allocation? = opts[:force] || false

    # Assign the process' "identity" from the TOP's point of view. It may either
    # be local (gateway_id == server_id) or remote (target_id == server_id).
    processes = identify_origin(server_id, processes)

    # Calculates the static resources that should be allocated to each process
    {static_resources_usage, allocated_processes} = static_allocation(processes)

    # Subtracts the total server resources with the allocated resources above,
    # on the `static_allocation` step.
    remaining_resources =
      Process.Resources.sub(total_resources, static_resources_usage)

    # Performs the dynamic allocation to every process. The result
    # (`allocated_processes`) already has the full allocation ready, i.e. it
    # contains both the static and the dynamic allocations.
    {dynamic_resources_usage, allocated_processes} =
      dynamic_allocation(remaining_resources, allocated_processes)

    # Subtracts the resources remaining (after the static allocation) with the
    # newly allocated dynamic resources.
    remaining_resources =
      Process.Resources.sub(remaining_resources, dynamic_resources_usage)

    # Now we'll take another pass, in order to give a change for processes to
    # claim unused resources. This may happen when a resource is reserved to a
    # process, but the process does not allocate it due to upper limitations
    {remaining_resources_usage, allocated_processes} =
      remaining_allocation(remaining_resources, allocated_processes)

    # Subtract again. Now we should be very close to 100% utilization. We'll
    # check to make sure it didn't overflow - if it didn't, the allocation was
    # successful.
    remaining_resources =
      Process.Resources.sub(remaining_resources, remaining_resources_usage)

    case overflow?(remaining_resources, allocated_processes) do
      # No overflow, we did it!
      false ->

        # Modify the Process model to include the `next_allocation`
        allocated_processes = merge_allocation(allocated_processes)

        result =
          %{
            dropped: [],  # TODO
            allocated: allocated_processes
          }

        {:ok, result}

      # Allocated more than we could handle :(
      {true, heaviest} ->
        {:error, :resources, heaviest}

    end
  end

  @spec merge_allocation([allocated_process]) ::
    [Process.t]
  defp merge_allocation(allocated_processes) do
    Enum.map(allocated_processes, fn {process, new_alloc} ->
      %{process| next_allocation: new_alloc}
    end)
  end

  @spec overflow?(Process.Resources.t, [allocated_process]) ::
    {true, heaviest :: [Process.t]}
    | false
  defp overflow?(remaining_resources, allocated_processes) do
    # Checks whether any of the resources are in overflow (usage > available)
    overflow? =
      Process.Resources.overflow?(remaining_resources, allocated_processes)

    empty_acc = {false, []}

    # The Enum below is used to detect that, in case more than one resource is
    # overflowed, the corresponding `heaviest` process is accumulated. This is
    # used to inform the top-level all the heaviest processes that should be
    # removed (if the `force` flag was passed as argument to the Allocator).
    {overflow?, heaviest} =
      Enum.reduce(overflow?, empty_acc, fn {_res, result}, {status, heaviest} ->
        case result do
          false ->
            {status, heaviest}

          {true, heavy} ->
            {true, heaviest ++ [heavy]}
        end
      end)

    if overflow? do
      uniq_heaviest = Enum.uniq_by(heaviest, &(&1.process_id))

      {true, uniq_heaviest}
    else
      false
    end
  end

  @spec static_allocation([Process.t]) ::
    {allocated :: Process.Resources.t, [allocated_process]}
  def static_allocation(processes) do
    initial = Process.Resources.initial()

    Enum.reduce(processes, {initial, []}, fn process, {allocated, acc} ->

      # Calculates how many resources should be allocated statically
      proc_static_allocation = Process.Resources.allocate_static(process)

      # Accumulates total static resources allocated by all processes
      allocated = Process.Resources.sum(allocated, proc_static_allocation)

      # This 2-tuple associates the process to its static allocation
      proc_alloc_info = [{process, proc_static_allocation}]

      {allocated, acc ++ proc_alloc_info}
    end)
  end

  @spec dynamic_allocation(Process.Resources.t, [allocated_process]) ::
    {Process.Resources.t, [allocated_process]}
  def dynamic_allocation(available_resources, allocated_processes) do
    initial = Process.Resources.initial()
    i = {initial, []}

    {total_shares, proc_shares} =
      Enum.reduce(allocated_processes, i, fn allocated_process, {shares, acc} ->
        {process, proc_static_allocation} = allocated_process

        # Calculates number of shares the process should receive
        proc_shares = Process.Resources.get_shares(process)

        # Accumulates total shares in use by the system
        shares = Process.Resources.sum(shares, proc_shares)

        # This 3-tuple represents what is the process, how many static resources
        # are allocated to it, and how many (dynamic) shares it should receive
        proc_share_info = [{process, proc_static_allocation, proc_shares}]

        {shares, acc ++ proc_share_info}
      end)

    # Based on the total shares selected, figure out how much resource each
    # share shall receive
    resource_per_share =
      Process.Resources.resource_per_share(available_resources, total_shares)

    Enum.reduce(proc_shares, i, fn allocated_shared_proc, {total_alloc, acc} ->
      {process, proc_static_allocation, proc_shares} = allocated_shared_proc

      # Allocates dynamic resources. "Naive" because it has not taken into
      # consideration the process limitations yet
      naive_dynamic_alloc =
        Process.Resources.allocate_dynamic(
          proc_shares, resource_per_share, process
        )

      limit = Process.get_limit(process)

      # Now we take the naive allocated amount and apply the process limitations
      proc_dynamic_alloc = Process.Resources.min(naive_dynamic_alloc, limit)

      # Sums static and dynamic allocation, resulting on the final allocation
      proc_allocation =
        Process.Resources.allocate(proc_dynamic_alloc, proc_static_allocation)

      # Accumulate total alloc, in order to know how many resources were used
      total_alloc = Process.Resources.sum(total_alloc, proc_dynamic_alloc)

      {total_alloc, acc ++ [{process, proc_allocation}]}
    end)
  end

  @spec remaining_allocation(Process.Resources.t, [allocated_process]) ::
    {Process.Resources.t, [allocated_process]}
  def remaining_allocation(available_resources, allocated_processes) do
    # Exclude processes that have limits
    # Note that this is wrong: it's possible that a process with limits would
    # benefit from a second pass, in the case that one of its resources were
    # limited, but the others weren't. We can safely skip this for now since
    # we don't have this scenario, but this could change in the future.
    processes =
      Enum.filter(allocated_processes, fn {process, _} ->
        Process.get_limit(process) == %{}
      end)

    skipped_processes = allocated_processes -- processes

    # Make a second pass on dynamic allocation, now only with processes that are
    # not being limited.
    {remaining_resources, processes} =
      dynamic_allocation(available_resources, processes)

    # Reorder the processes in the same order they were passed originally
    # Useful for tests, probably irrelevant to production code. Maybe macro it.
    ordered_processes =
      Enum.reduce(allocated_processes, [], fn allocated = {process, _}, acc ->

        if allocated in skipped_processes do
          acc ++ [allocated]
        else
          proc =
            Enum.find(
              processes, fn {p, _} -> p.process_id == process.process_id end
            )

          acc ++ [proc]
        end
      end)

    {remaining_resources, ordered_processes}
  end
end
