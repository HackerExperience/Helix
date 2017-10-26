defmodule Helix.Process.Model.TOP.Allocator do

  alias Helix.Process.Model.Process

  # @spec allocate(server_resources, [Process.t]) ::
  #   [{Process.t, allocated_resources}]
  def allocate(total_resources, processes) when is_list(processes) do

    # First pass: static resources allocation
    {static_resources_usage, allocated_processes} = static_allocation(processes)

    ### server_resources = ProcessResources.map_server_resources(server_res)

    remaining_resources =
      Process.Resources.sub(total_resources, static_resources_usage)

    case overflow?(remaining_resources, allocated_processes) do
      false ->
        {dynamic_resources_usage, allocated_processes} =
          dynamic_allocation(remaining_resources, allocated_processes)

        remaining_resources =
          Process.Resources.sub(remaining_resources, dynamic_resources_usage)

        case overflow?(remaining_resources, allocated_processes) do
          false ->
            allocated_processes

          {true, heaviest} ->
            {:error, :resources, heaviest}

        end

      {true, heaviest} ->
        {:error, :resources, heaviest}
        # heaviest = get_heaviest(allocated_processes)
        # processes = processes -- [drop(heaviest)]
        # allocate(server_resources, processes)
    end
  end

  defp overflow?(remaining_resources, allocated_processes) do
    overflow? =
      Process.Resources.overflow?(remaining_resources, allocated_processes)

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
      {true, heaviest}
    else
      false
    end
  end

  def static_allocation(processes) do
    initial = Process.Resources.initial()

    {static_resources_usage, allocated_processes} =
      Enum.reduce(processes, {initial, []}, fn process, {allocated, acc} ->
        # PR.allocate_static
        proc_static_allocation = Process.Resources.allocate_static(process)

        # Sum (acc)
        allocated = Process.Resources.sum(allocated, proc_static_allocation)
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
        # PR.get_shares
        proc_shares = Process.Resources.get_shares(process)

        # Acc (sum)
        shares = Process.Resources.sum(shares, proc_shares)
        proc_share_info = [{process, proc_static_allocation, proc_shares}]

        {shares, acc ++ proc_share_info}
      end)

    resource_per_share =
      Process.Resources.resource_per_share(available_resources, total_shares)

    Enum.reduce(process_shares, {initial, []}, fn allocated_shared_proc, {total_alloc, acc} ->
      {process, proc_static_allocation, proc_shares} = allocated_shared_proc

      # Resource.allocate_dynamic
      proc_dynamic_alloc =
        Process.Resources.allocate_dynamic(proc_shares, resource_per_share, process)

      # Resource.allocate
      proc_allocation =
        Process.Resources.allocate(proc_dynamic_alloc, proc_static_allocation)

      # Acc (Nao usa Resource?)
      total_alloc = Process.Resources.sum(total_alloc, proc_dynamic_alloc)

      {total_alloc, acc ++ [{process, proc_allocation}]}
    end)
  end
end
