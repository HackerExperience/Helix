defmodule Helix.Process.Model.TOP.Allocator do
  @moduledoc """
  Welcome to the TOP.Allocator. The Allocator is responsible for figuring out
  how many resources each process on the server is allowed to allocate. That's
  all it does. Simple, right? Now, there are several factors that affect the
  resulting allocation, and because of that calculating the correct amount of
  resources each process can use is actually quite complex. Let me try to
  explain the idea behind allocation:

  # Primer

  It all starts with the server. A server has resources, like CPU, RAM, ULK
  (uplink) and DLK (downlink).

  A process, in order to finish whatever it's supposed to do, must consume an
  amount of resources. The total amount of resources a process needs to compute
  before it's deemed completed is called `objective`.

  We use the same data structure to represent a process' objective, allocated
  resources, limitations, and total amount of work that it has already computed.
  This data structure is called `Resources`, and it's actually quite similar to
  a matrix. In fact, all the Allocator does is a bunch of matrix operations.
  (Actually array may be more accurate than matrix).

  So, for instance, want to know how long it will take to compute a process?

  1. Subtract its `objective` to its `processed`

  This will yield the work left to complete the process

  2. Divide the work left with the process' total allocated resources

  If you assume the process allocation represents resources consumed in one
  second, this operation will yield the seconds left for each resource to reach
  the process `objective`.

  3. From the result above, get the `max()` value.

  The max value represents the slowest resource to meet the process objective.
  Once this happens, all other resources should have already reached the
  objective.

  Simple, right? That's the gist of both Allocator and Scheduler. But back to
  the factors that make this an extremely complex system.

  # Getting to know our challenges

  Here are a few factors that TOP must consider when Allocating resources:

  1. A process may use all, one or zero resources from a server. Resources that
  a process does not use should never be allocated to it. Instead, these
  resources must be available to other processes who actually need them.

  2. A process may have a minimum amount of resources it uses. This is called
  `static`, later on referred to as the "Static Allocation" of a process.

  3. A process may have a maximum amount of resources it may use. This is
  referred to as the `limit` of a process.

  4. A process may consume all available resources on the server (as long as it
  needs that resource, see 1). This is referred as "Dynamic Allocation" of a
  process. Dynamic because it depends on how many server resources are available

  5. A process may be paused. A paused process does not consume available server
  resources (dynamic) but it may consume a minimum amount of resources (static).
  As such, the `static` resource consumption of a process exists for both when
  it is running, and when it is paused, and it may have different values.

  6. A process may have a priority relative to other processes on the same
  server. A process with higher priority receives more resource shares than
  others with lower priority.

  7. A process allocation may change if more or less server resources are made
  available (e.g. in the case another process has completed or started). When
  this happens, the process needs to have its allocation recalculated, taking
  in consideration the new amount of server resources.

  8. The sum of all processes allocation must not exceed the available resources
  on a server, in which case we have a resource overflow scenario.

  9. When a process allocation changes, we need to store somewhere how many
  resources it had processed before, with the previous amount allocated.

  10. A process may exist on two different servers, referred to as `local` and
  `remote` (or with the prefix `l_` and `r_`, respectively).

  11. Because of 10, the total resources allocated on a process may be limited
  by the remote server's resources (e.g. a FileTransferProcess may be limited by
  the remote server's ULK or DLK.).

  12. Similar to 7, if more resources are made available on the remote server,
  we must recalculate the process allocation on both the local and the remote
  servers, since now the process may be allowed to allocate more or less
  resources.

  13. In fact, a process' limit and dynamic consumption, described on items 3
  and 4 respectively, also apply to the remote server.

  (In order to keep the mental sanity of Helix developers, we've postponed the
  option for remote processes to have their own `objective`, `processed` and
  `static` allocation. But it's doable, and probably needed for MalwareProcess).

  14. When the total resources available in a server changes, this may affect
  all processes that target/originate from this server (12). When recalculating
  the resources used on these other processes, it may be the case that *their*
  recalculations would affect processes that target/originate *them*, in which
  case they should be recalculated too. And so on. Recursively.

  15. Oh, it must be fast - less than 1ms. And accurate - millisecond accurate.
  And simple to understand.

  ---

  I may have forgotten some, but by now you should have an idea of what we are
  dealing with. Ready to continue?

  # Solution to the Allocator problem

  ## High-level overview

  Let's start with a high-level overview of how we've solved this problem.

  In order to allocate resources for all processes, we make 3 "allocation
  passes". They are:

  1. Static allocation
  2. Dynamic allocation
  3. Remaining allocation

  The first pass is the static allocation. Here we need to ensure that all
  processes are able to allocate the minimum they need. Static allocation is
  non-negotiable, isn't affected by priority nor how many available resources
  are there in the server.

  After the first pass, we keep track of how many resources are left in the
  server. Now we'll iterate again over all processes, allowing them to get as
  many resources as they want - but limited by their `limit`.

  The second pass is usually where most of the resources are allocated. However,
  if any process has an upper limit that is lower than what is available on the
  server, we won't be able to allocate 100% of our resources.

  That's where the third pass comes to play. We once again keep track of the
  remaining resources available on the server (which by now is probably little).
  Then we eliminate from this pass the processes that have limits - they already
  received what they were supposed to. Finally, we share the remaining resources
  with the processes that do not have any kind of limitations. This is very
  similar to a dynamic allocation, except we filtered out processes that have
  upper limits.

  For each allocation step, we check whether the process is `local` or `remote`,
  and only update the corresponding field (`l_*` or `r_*`).

  That's all there is to it!

  (Well, there is more, but as far as the Allocator is concerned, that's it).

  ## Detailed explanation

  Too tired to explain. Read code + comments.

  ## The secret sauce

  If you've read the Challenges section carefully, you might realize that the
  solution described above does not solve, alone, challenges 11 and 12. And you
  are correct!

  The Allocator is very selfish: if the process is local to the server, it only
  updates the local fields (`l_*`). If it's remote, it only updates the remote
  ones (`r_*`).

  So imagine that player A is downloading a file from his gigabit internet from
  player B, which is a Comcast user. Naturally, player A's download speed will
  be severely limited by player's B ULK (uplink).

  However the Allocator does not care: it will happily *reserve* all of player
  A's DLK to the process (if it's the only one in use).

  The actual allocation, how many resources are *actually* used by the process,
  is calculated on `Process.infer_usage`, and *that* steps takes into
  consideration both the `local` and `remote` limitations. This means that
  Allocator *reserves* resources optimistically, but the actual allocation is
  done by the Process model.

  This has several pros at the cost of one big downside: It greatly simplifies
  Allocation, specially when considering challenges 12 and 15, at the cost of
  possibly some poorly allocated resources (in some very specific, but real,
  cases).

  The good news is that it's possible to minimize the "mis-allocation" by taking
  some simple steps. The bad news is that I don't have the time to do them now.

  So, all in all, it's GoodEnoughForNow™.
  """

  alias Helix.Server.Model.Server
  alias Helix.Process.Model.Process

  @type shares :: number

  @spec identify_origin(Server.id, [Process.t]) ::
    [Process.t]
  defp identify_origin(server_id, processes) do
    Enum.map(processes, fn process ->
      local? =
        if process.gateway_id == server_id do
          true
        else
          false
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
  @doc """
  Allocates the `total_resources` of `server_id` into each given process.

  For a detailed explanation of how it works, read the module doc.
  """
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
      reserved_resources =
        process.local? && process.l_reserved || process.r_reserved

      # If the new allocation is identical to what has been allocated before,
      # then there's no need to set `next_allocation`
      # This solves #343. If you absolutely need that `next_allocation` is set
      # every time, regardless if it changed, some tweak will have to be made on
      # `Scheduler.seconds_for_completion`, so it knows exactly what allocation
      # to use.
      if reserved_resources == new_alloc do
        process
      else
        %{process| next_allocation: new_alloc}
      end
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

    # Based on the total shares selected, figure out how many resources each
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
