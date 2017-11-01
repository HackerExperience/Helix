defmodule Helix.Process.Action.TOP do

  import HELL.Macros

  alias Helix.Event
  alias Helix.Server.Model.Server
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Processable
  alias Helix.Process.Model.TOP
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Process.Event.Process.Completed, as: ProcessCompletedEvent
  alias Helix.Process.Event.TOP.BringMeToLife, as: TOPBringMeToLifeEvent

  def complete(process) do
    case TOP.Scheduler.simulate(process) do
      {:completed, _process} ->
        {_, e1} = Processable.conclusion(process.data, process)

        e2 = ProcessCompletedEvent.new(process)

        {:ok, e1 ++ [e2]}

      {:running, _process} ->
        {:error, {:process, :running}, []}
    end
  end

  def recalque(server_id = %Server.ID{}, alloc_opts \\ []) do
    alias Helix.Server.Query.Server, as: ServerQuery
    alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
    server = ServerQuery.fetch(server_id)

    # TODO: Move method below to TOPQuery/ProcessQuery
    resources =
      server.motherboard_id
      |> MotherboardQuery.fetch()
      |> MotherboardQuery.resources()

    {server_dlk, server_ulk} =
      Enum.reduce(
        resources.net,
        {%{}, %{}},
        fn {network, %{downlink: dlk, uplink: ulk}}, {acc_dlk, acc_ulk} ->

        acc_dlk =
          %{}
          |> Map.put(network, dlk)
          |> Map.merge(acc_dlk)

        acc_ulk =
          %{}
          |> Map.put(network, ulk)
          |> Map.merge(acc_ulk)

        {acc_dlk, acc_ulk}
      end)

    server_resources =
      %{
        cpu: resources.cpu,
        ram: resources.ram,
        dlk: server_dlk,
        ulk: server_ulk
      }

    processes = ProcessQuery.get_processes_on_server(server_id)

    case TOP.Allocator.allocate(server_resources, processes, alloc_opts) do
      {:error, :resources, _} ->
        {:error, :resources}

      {:ok, allocation_result} ->
        processes = schedule(allocation_result)

        event = []  # TOPRecalcado
        {:ok, processes, [event]}
    end
  end

  defp schedule(%{allocated: processes, dropped: _dropped}) do
    # Forecast will be used to figure out which process is the next to be
    # completed. This is the first - and only - time these processes will be
    # simulated, so we have to ensure the return of `forecast/1` is served as
    # input for the Checkpoint step below.
    forecast = TOP.Scheduler.forecast(processes)

    # This is our new list of processes. It accounts for all process that are
    # not completed, so it contains:
    # - paused processes
    # - running processes
    # - processes awaiting allocation
    processes = forecast.paused ++ forecast.running

    # On a separate thread, we'll "handle" the forecast above. Basically we'll
    # track the completion date of the `next`-to-be-completed process.
    # Here we also deal with processes that were deemed already completed by the
    # simulation.
    hespawn fn -> handle_forecast(forecast) end

    # The Checkpoint step is done to update the processes with their new
    # allocation, as well as the amount of work done previously on `processed`.
    # We'll accumulate all processes that should be updated to a list, which
    # will later be passed on to `handle_checkpoint`.
    {processes, processes_to_update} =
      Enum.reduce(processes, {[], []}, fn process, {acc_procs, acc_update} ->

        # Call `Scheduler.checkpoint/2`, which will let us know if we should
        # update the process or not.
        # Also accumulates the new process (may have changed `allocated` and
        # `last_checkpoint_time`).
        case TOP.Scheduler.checkpoint(process) do
          {true, changeset} ->
            process = Ecto.Changeset.apply_changes(changeset)
            {acc_procs ++ [process], acc_update ++ [changeset]}

          false ->
            {acc_procs ++ [process], acc_update}
        end
      end)

    # Based on the return of `checkpoint` above, we've accumulated all processes
    # that should be updated. They will be passed to `handle_checkpoint`, which
    # shall be responsible of properly handling this update in a transaction.
    hespawn(fn -> handle_checkpoint(processes_to_update) end)

    # Returns a list of all processes the new server has (excluding completed
    # ones). The processes in this list are updated with the new `allocation`,
    # `processed` and `last_checkpoint_time`.
    # Notice that this updated data hasn't been updated yet on the DB. It is
    # being performed asynchronously, in a background process.
    processes
  end

  defp handle_forecast(%{completed: completed, next: next}) do
    handle_completed(completed)
    handle_next(next)
  end

  defp handle_completed([]),
    do: :noop
  defp handle_completed(completed) do
    Enum.each(completed, fn completed_process ->
      with {:ok, events} <- complete(completed_process) do
        Event.emit(events)
      end
    end)
  end

  defp handle_next({process, time_left}) do
    wake_me_up = TOPBringMeToLifeEvent.new(process)
    save_me = time_left * 1000 |> trunc()

    # Wakes me up inside
    Event.emit_after(wake_me_up, save_me)
  end
  defp handle_next(_),
    do: :noop

  alias Helix.Process.Internal.Process, as: ProcessInternal
  defp handle_checkpoint(wut) do
    # Updates process with new `allocated`, `last_checkpoint_time`
    ProcessInternal.batch_update(wut)
  end
end
