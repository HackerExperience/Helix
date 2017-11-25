defmodule Helix.Process.Model.TOP.Scheduler do
  @moduledoc """
  The `TOP.Scheduler` receives a process, or a list of processes, that were
  previously Allocated and figures out stuff like:

  - How long will it take for it to be completed?
  - Oh, is it already completed?
  - From all processes on the server, which is the next one to be completed?
  """

  import HELL.Macros

  alias Ecto.Changeset
  alias Helix.Process.Model.Process

  @type forecast ::
    %{
      next: {Process.t, Process.time_left} | nil,
      paused: [Process.t],
      completed: [Process.t],
      running: [Process.t]
    }

  @spec simulate(Process.t) ::
    {:completed, Process.t}
    | {:running, Process.t}
    | {:paused, Process.t}
  @doc """
  `simulate/1` will simulate how many resources were computed/processed by the
  process since the last time it changed (may be its creation date or the last
  checkpoint date).

  Then, based on the process allocation, figures out whether it is still running
  or completed. It also modifies the Process struct with the updated `processed`
  information.

  Note that `simulate/1` uses `l_allocated`, i.e. the "currently" allocated
  resources. That's because `simulate/1` happens from the past (last update) to
  the present time. It does not consider would-be allocations in the future. For
  this, check `seconds_for_completion`.

  It has a special behaviour if the process' state is `:waiting_allocation`: it
  will modify the process state to `:running`. This is done because `simulate/1`
  (and all methods on `TOP.Scheduler`) are called from `TOP.Action`, after the
  process was allocated. So it's safe to update the Process state to `:running`.

  """
  def simulate(process = %{state: :paused}),
    do: {:paused, process}
  def simulate(process = %{state: :waiting_allocation}) do
    processed = process.processed || Process.Resources.initial()

    process =
      %{process|
        processed: processed,
        state: :running
       }

    {:running, process}
  end

  def simulate(process) do
    # Based on the last checkpoint, figure out how long this simulation should
    # run
    simulation_duration = get_simulation_duration(process)

    # Create an empty resource map in case it never went through a checkpoint
    processed = process.processed || Process.Resources.initial()

    # Convert allocation to millisecond
    alloc = Process.Resources.map(process.l_allocated, &(&1 / 1000))

    # Calculate how many resource units have been processed since the last
    # checkpoint. This is the amount that should be added to the process.
    moar_processed =
      Process.Resources.map(alloc, &(&1 * simulation_duration))

    # Sum the previous `processed` and the amount that has been processed since
    # the last checkpoint
    new_processed = Process.Resources.sum(processed, moar_processed)

    process = %{process| processed: new_processed}

    # If all resources in `new_processed` are equal or superior to their
    # corresponding resource on the `objective`, then the process is finished.
    completed? = Process.Resources.completed?(new_processed, process.objective)

    if completed? do
      {:completed, process}
    else
      {:running, process}
    end
  end

  @spec forecast([Process.t]) ::
    forecast
  @doc """
  `forecast/1` is a high-level function that receives a list of all processes
  on a server, after they received allocation, and returns some useful data,
  including:

  - The next-to-be-completed process (if any), and how many seconds are left.
  - A list of processes that are already completed.
  - A list of processes that are running (includes the `next`-to-be-completed).
  - A list of processes that are paused.
  """
  def forecast(processes) do
    initial_acc = %{next: nil, paused: [], completed: [], running: []}

    processes
    |> Enum.map(&estimate_completion/1)
    |> Enum.reduce(initial_acc, fn {process, seconds_left}, acc ->

      case seconds_left do
        # Process will never complete; (paused or hasn't got any allocation yet)
        :infinity ->
          %{acc| paused: acc.paused ++ [process]}

        # Process has already reached its objective; it's completed.
        -1 ->
          %{acc| completed: acc.completed ++ [process]}

        # Process would need to run for almost zero seconds... it's completed.
        0.00 ->
          %{acc| completed: acc.completed ++ [process]}

        # Add the process to the list of running processes, and maybe select it
        # to be marked as `next`, depending on whether it would be completed
        # first.
        seconds ->
          %{acc|
            running: acc.running ++ [process],
            next: sort_next_completion(acc.next, {process, seconds})
           }
      end
    end)
  end

  @spec estimate_completion(Process.t) ::
    {Process.t, Process.time_left | -1 | :infinity}
  @doc """
  `estimate_completion/1` will, as the name says, estimate how long it will take
  for the process to reach its current objectives.

  It may return `:infinity` if the process is paused or do not have allocated
  resources to it; and `-1` if the process is already completed.
  """
  def estimate_completion(process) do
    process
    |> simulate()
    |> seconds_for_completion()
  end

  @spec checkpoint(Process.t) ::
    {true, Process.changeset}
    | false
  @doc """
  `checkpoint/1` marks a milestone on the Process. When the process allocation
  changes, it will store on the database how many resources have already been
  `processed` by the process on the previous allocation. This is important so
  we do not lose track of previous progress done towards the final objective.

  Notice that if the allocation did not change (i.e. the `next_allocation` is
  exactly equal to `[l|r]_reserved`) we do not need to update this information,
  since the next time the process would be fetched, `simulate/1`, `forecast/1`
  and `estimate_completion/1` would all be able to predict exactly how many
  resources were processed in the meantime between the last update.

  However, if the allocation changes, that's not possible to do without having
  an extra input - the previously `processed` resources. That's why here on
  `checkpoint/1` we update the Process' `last_checkpoint_time`. Everything that
  happened *before* the `last_checkpoint_time` is already saved on `processed`.
  """
  def checkpoint(%{l_reserved: alloc, next_allocation: alloc, local?: true}),
    do: false
  def checkpoint(%{r_reserved: alloc, next_allocation: alloc, local?: false}),
    do: false
  def checkpoint(proc = %{next_allocation: next_allocation, local?: true}) do
    changeset =
      proc
      |> Changeset.change()
      |> Changeset.put_change(:l_reserved, next_allocation)
      |> Changeset.put_change(:last_checkpoint_time, DateTime.utc_now())

    changeset =
      if proc.processed == Process.Resources.initial() do
        changeset
      else
        Changeset.force_change(changeset, :processed, proc.processed)
      end

    {true, changeset}
  end
  def checkpoint(proc = %{next_allocation: next_allocation, local?: false}) do
    {_, proc} = simulate(proc)

    changeset =
      proc
      |> Changeset.change()
      |> Changeset.put_change(:r_reserved, next_allocation)
      |> Changeset.put_change(:last_checkpoint_time, DateTime.utc_now())
      |> Changeset.force_change(:processed, proc.processed)

    {true, changeset}
  end

  @spec get_simulation_duration(Process.t) ::
    pos_integer
  docp """
  Figures out for how long the simulation performed at `simulate/1` should take.

  See doc on `checkpoint/1` to understand why we need to select earliest of
  `last_checkpoint_time` or `creation_date`.
  """
  defp get_simulation_duration(process) do
    now = DateTime.utc_now()
    last_update = Process.get_last_update(process)

    DateTime.diff(now, last_update, :millisecond)
  end

  @spec seconds_for_completion({:paused | :completed | :running, Process.t}) ::
    {Process.t, Process.time_left | -1 | :infinity}
  docp """
  `seconds_for_completion/1` will calculate the time left in order for the
  process to reach its `objective`.

  Notice it uses `next_allocation` (if available), so if the process allocation
  changed, it will consider the new allocation. That's OK because we are
  considering what would happen from the present time to the future, which uses
  the new allocation.

  Contrast it to `simulate/1`, which simulates the process from the past (last
  update time) to the present.
  """
  defp seconds_for_completion({:paused, process}),
    do: {process, :infinity}
  defp seconds_for_completion({:completed, process}),
    do: {process, -1}
  defp seconds_for_completion({:running, process}) do
    # This is the amount of work left for completion of the process
    remaining_work = Process.Resources.sub(process.objective, process.processed)

    next_allocation = process.next_allocation || process.l_allocated

    # Convert allocation to millisecond
    alloc = Process.Resources.map(next_allocation, &(&1 / 1000))

    # Figure out the work left in order to complete each resource
    work_left =
      if alloc == Process.Resources.initial() do
        remaining_work
      else
        # TODO: Div is not correct when alloc is 0 (see `safe_div/1`)
        Process.Resources.div(remaining_work, alloc)
      end

    # Return a raw number (float) representing how many seconds it would need
    # to complete the resource with more work left to do.
    # So if this process needs 10 seconds to complete its CPU objective, and 30s
    # to complete the DLK objective, it will return 30s.
    estimated_seconds =
      work_left
      |> Process.Resources.max_value()
      |> Kernel./(1000)  # From millisecond to second
      |> Float.round(2)

    {process, estimated_seconds}
  end

  @spec sort_next_completion(nil | {Process.t, term}, {Process.t, term}) ::
    {Process.t, term}
  docp """
  Helper of `forecast/1`, used to determine whether the candidate process would
  finish before the currently selected "next-to-finish" process. If so, we need
  to replace the selected process with the candidate one, as we want to return
  the first process that will be completed.
  """
  defp sort_next_completion(nil, {process, seconds}),
    do: {process, seconds}
  defp sort_next_completion(current, candidate) do
    {_, cur_seconds} = current
    {_, candidate_seconds} = candidate

    # If the currently selected process is bound to finish before the candidate,
    # then we must keep the current selection and reject the candidate.
    # Otherwise, the candidate will finish first, and must be selected.
    if cur_seconds < candidate_seconds do
      current
    else
      candidate
    end
  end
end
