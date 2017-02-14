defmodule Helix.Process.Controller.TableOfProcesses.Allocator.Plan do

  alias Ecto.Changeset
  alias Helix.Process.Controller.TableOfProcesses.ServerResources
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Process.Resources

  @type process_id :: HELL.PK.t
  @type network_id :: HELL.PK.t

  @type process :: Process.t | %Ecto.Changeset{data: Process.t}

  @type shares_plan :: %{
    cpu: non_neg_integer,
    ram: non_neg_integer,
    net: %{optional(network_id) => %{dlk: non_neg_integer, ulk: non_neg_integer}}
  }

  @type t :: plan :: %{
    current_plan: %{
      fragment: ServerResources.t,
      processes: [{process, [:cpu | :ram | :dlk | :ulk]}]
    },
    next_plan: %{
      shares: shares_plan,
      processes: [{process, [:cpu | :ram | :dlk | :ulk]}]
    },
    acc: [process]
  }

  @spec allocate([process], ServerResources.t) :: [Ecto.Changeset.t]
  def allocate(processes, resources) do
    processes
    |> plan(resources)
    |> execute()
  end

  # TODO: accumulate on the "plan" the amount of allocation rounds needed and
  #   return those changesets inside a map containing that debug info. That way
  #   we can metrify (?) the TOP and possibly optimize it
  @spec plan([process], ServerResources.t) :: {t, ServerResources.t} | {:error, :insuficient_resources}
  defp plan(processes, resources) do
    keikaku = %{
      current_plan: %{fragment: %ServerResources{}, processes: []},
      next_plan: %{shares: %{cpu: 0, ram: 0, net: %{}}, processes: []},
      acc: []
    }

    preallocate(processes, keikaku, resources)
  end

  # REVIEW: I was pretty tired when i wrote this. It should be refactored later
  @spec preallocate([process], t, ServerResources.t) :: {t, ServerResources.t} | {:error, :insuficient_resources}
  defp preallocate([h| t], plan, resources) do
    process = Process.allocate_minimum(h)
    net_id = Changeset.get_field(process, :network_id)

    # REVIEW: TODO: the return format still seems odd and this code is getting
    #   complicated
    case ServerResources.sub_from_process(resources, process) do
      {:ok, resources} ->
        case allocable_resources(process, resources) do
          [] ->
            plan = Map.update!(plan, :acc, &([process| &1]))

            preallocate(t, plan, resources)
          res_types ->
            shares = Changeset.get_field(process, :priority)

            plan =
              plan
              |> update_in([:next_plan, :processes], &([{process, res_types}| &1]))
              |> update_in([:next_plan, :shares], &merge_share(&1, res_types, shares, net_id))

            preallocate(t, plan, resources)
        end
      error ->
        error
    end
  end

  defp preallocate([], plan, r),
    do: {plan, r}

  @spec allocable_resources(process, ServerResources.t) :: [:cpu | :ram | :dlk | :ulk]
  defp allocable_resources(process, %{cpu: cpu, ram: ram, net: networks}) do
    net_id = Changeset.get_field(process, :network_id)
    net = Map.get(networks, net_id, [dlk: 0, ulk: 0])

    # Returns a list of resource types that the server can't allocate for the
    # process so we can reject them from the resources the process ask
    # This is done so we can avoid trying to allocate resources a process can't
    # receive
    shouldnt =
      net
      |> Enum.to_list()
      |> Kernel.++([cpu: cpu, ram: ram])
      |> Enum.filter_map(fn {_, v} -> v == 0 end, &elem(&1, 0))

    Process.can_allocate(process) -- shouldnt
  end

  @spec execute({t, ServerResources.t}) :: [Ecto.Changeset.t]
  @spec execute({:error, any}) :: {:error, any}
  defp execute(error = {:error, _}),
    do: error
  defp execute({plan = %{}, resources = %{}}) do
    plan
    |> execute_step(resources)
    |> Map.fetch!(:acc)
  end

  @spec execute_step(t, ServerResources.t) :: t
  defp execute_step(plan = %{current_plan: %{fragment: fragment, processes: [{process, required_resources}| t]}}, resources) do
    shares = Changeset.get_field(process, :priority)
    net_id = Changeset.get_field(process, :network_id)

    allocate =
      fragment.net
      |> Map.get(net_id, %{})
      |> Enum.into(%{cpu: fragment.cpu, ram: fragment.ram}) # Prepare a map with resources that the process might want
      |> Map.take(required_resources) # Filter out those that it didn't request
      |> Enum.map(fn {k, v} -> {k, v * shares} end)
      |> :maps.from_list()

    allocated_proccess = Process.allocate(process, allocate)

    allocated_before = Changeset.get_field(process, :allocated)
    allocated_after = Changeset.get_field(allocated_proccess, :allocated)

    if allocated_before == allocated_after do
      # Nothing was changed, so this process won't receive any more allocation
      plan
      |> put_in([:current_plan, :processes], t)
      |> Map.update!(:acc, &([process| &1]))
      |> execute_step(resources)
    else
      can_allocate = Process.can_allocate(allocated_proccess)

      resources_diff = Resources.sub(allocated_after, allocated_before)
      resources = ServerResources.sub_from_resources(resources, resources_diff, net_id)

      plan
      |> put_in([:current_plan, :processes], t)
      |> update_in([:next_plan, :processes], &([{allocated_proccess, can_allocate}| &1]))
      |> update_in([:next_plan, :shares], &merge_share(&1, can_allocate, shares, net_id))
      |> execute_step(resources)
    end
  end

  defp execute_step(p = %{current_plan: %{processes: []}, next_plan: %{processes: []}}, _) do
    p
  end

  defp execute_step(plan = %{current_plan: %{processes: []}, next_plan: next_plan}, resources) do
    %{processes: processes, shares: shares} = next_plan

    # TODO: Maybe, instead of storing the shares the process asks for, just
    # store the process prio and what it is requesting, then, at this step,
    # filter out the requests that can't be completed because the resource
    # is all used (so we can save a few computations) and use the lowest common
    # denominator of the priority of the rest of processes to allocate more
    # properly the total amount of resources possible

    fragment = ServerResources.part_from_shares(resources, shares)

    # Let's simply update it to avoid forgetting we should keep the acc :joy:
    plan = %{plan|
      current_plan: %{processes: processes, fragment: fragment},
      next_plan: %{shares: %{cpu: 0, ram: 0, net: %{}}, processes: []}
    }

    execute_step(plan, resources)
  end

  @spec merge_share(shares_plan, [:cpu | :ram | :dlk | :ulk], non_neg_integer, network_id) :: shares_plan
  defp merge_share(shares, requested_resources, priority, net_id) do
    Enum.reduce(requested_resources, shares, fn
      :cpu, acc = %{cpu: cpu} ->
        %{acc| cpu: cpu + priority}
      :ram, acc = %{ram: ram} ->
        %{acc| ram: ram + priority}
      link, acc = %{net: networks} when link in [:ulk, :dlk] ->
        updated_networks =
          networks
          |> Map.put_new(net_id, %{dlk: 0, ulk: 0})
          |> update_in([net_id, link], &(&1 + priority))

        %{acc| net: updated_networks}
    end)
  end
end