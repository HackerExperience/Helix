defmodule Helix.Process.Model.TOP.Scheduler do

  alias Ecto.Changeset
  alias Helix.Process.Model.Process

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
    alloc = Process.Resources.map(process.allocated, &(&1 / 1000))

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
        0.0 ->
          %{acc| completed: acc.completed ++ [process]}

        # Add the process to the list of running processes, and maybe select it
        # to be marked as `next`, depending on whether it would be completed
        # first.
        seconds ->
          %{acc|
            running: acc.running ++ [process],
            next: sort_next_completion(acc, {process, seconds})
           }
      end
    end)
  end

  def estimate_completion(process) do
    process
    |> simulate()
    |> seconds_for_completion()
  end

  def checkpoint(p = %{allocated: alloc, next_allocation: alloc}),
    do: false
  def checkpoint(process = %{next_allocation: next_allocation}) do
    changeset =
      process
      |> Changeset.change()
      |> Changeset.put_change(:allocated, next_allocation)
      |> Changeset.put_change(:last_checkpoint_time, DateTime.utc_now())

    {true, changeset}
  end

  defp get_simulation_duration(process) do
    now = DateTime.utc_now()

    if process.last_checkpoint_time do
      DateTime.diff(now, process.last_checkpoint_time, :millisecond)
    else
      DateTime.diff(now, process.creation_time, :millisecond)
    end
  end

  # defp seconds_for_completion({:waiting_alloc, process}),
  #   do: {process, :infinity}
  defp seconds_for_completion({:paused, process}),
    do: {process, :infinity}
  defp seconds_for_completion({:completed, process}),
    do: {process, -1}
  defp seconds_for_completion({:running, process}) do
    # This is the amount of work left for completion of the process
    remaining_work = Process.Resources.sub(process.objective, process.processed)

    # Convert allocation to millisecond
    alloc = Process.Resources.map(process.next_allocation, &(&1 / 1000))

    # Figure out the work left in order to complete each resource
    work_left = Process.Resources.div(remaining_work, alloc)

    # Return a raw number (float) representing how many seconds it would need
    # to complete the resource with more work left to do.
    # So if this process needs 10 seconds to complete its CPU objective, and 30s
    # to complete the DLK objective, it will return 30s.
    estimated_seconds =
      work_left
      |> Process.Resources.max()
      |> Kernel./(1000)  # From millisecond to second
      |> Float.round(1)

    {process, estimated_seconds}
  end

  defp sort_next_completion(%{next: nil}, {process, seconds}),
    do: {process, seconds}
  defp sort_next_completion(%{next: current}, candidate) do
    {cur_proc, cur_seconds} = current
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
