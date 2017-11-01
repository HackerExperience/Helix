defmodule Helix.Process.Model.TOP.Allocator do

  alias Helix.Process.Model.Process

  # @spec allocate(server_resources, [Process.t]) ::
  #   [{Process.t, allocated_resources}]
  def allocate(total_resources, processes, opts \\ []) do
    forced_allocation? = opts[:force] || false

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
    # newly allocated dynamic resources. If there was no overflow on this second
    # step (dynamic_allocation), the allocation was successful.
    remaining_resources =
      Process.Resources.sub(remaining_resources, dynamic_resources_usage)

    case overflow?(remaining_resources, allocated_processes) do
      false ->
        # No overflow, we did it!

        # Modify the Process model to include the `next_allocation`
        allocated_processes = merge_allocation(allocated_processes)

        result =
          %{
            dropped: [],  # TODO
            allocated: allocated_processes
          }

        {:ok, result}

      {true, heaviest} ->
        # Allocated more than we could handle :(
        {:error, :resources, heaviest}

    end
  end

  defp merge_allocation(allocated_processes) do
    Enum.map(allocated_processes, fn {process, new_alloc} ->
      %{process| next_allocation: new_alloc}
    end)
  end

  defp overflow?(remaining_resources, allocated_processes) do
    # Checks whether any of the resources are in overflow (usage > available)
    overflow? =
      Process.Resources.overflow?(remaining_resources, allocated_processes)

    # The Enum below is used to detect that, in case more than one resource is
    # overflowed, the corresponding `heaviest` process is accumulated. This is
    # used to inform the top-level all the heaviest processes that should be
    # removed (if the `force` flag was passed as argument to the Allocator).
    {overflow?, heaviest} =
      Enum.reduce(overflow?, {false, []}, fn {_res, result}, {status, heaviest} ->
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

  def static_allocation(processes) do
    initial = Process.Resources.initial()

    {static_resources_usage, allocated_processes} =
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

  # @type share :: %{cpu: ....}
  def dynamic_allocation(available_resources, allocated_processes) do
    initial = Process.Resources.initial()

    {total_shares, process_shares} =
      Enum.reduce(allocated_processes, {initial, []}, fn allocated_process, {shares, acc} ->
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

    Enum.reduce(process_shares, {initial, []}, fn allocated_shared_proc, {total_alloc, acc} ->
      {process, proc_static_allocation, proc_shares} = allocated_shared_proc

      # Allocates dynamic resources
      proc_dynamic_alloc =
        Process.Resources.allocate_dynamic(proc_shares, resource_per_share, process)

      # Sums static and dynamic allocation, resulting on the final allocation
      proc_allocation =
        Process.Resources.allocate(proc_dynamic_alloc, proc_static_allocation)

      total_alloc = Process.Resources.sum(total_alloc, proc_dynamic_alloc)

      {total_alloc, acc ++ [{process, proc_allocation}]}
    end)
  end
end
