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
    |> execute_step(resources)
    |> Map.fetch!(:acc)
  end

  @spec plan([process], ServerResources.t) :: t
  defp plan(processes, resources) do
    keikaku = %{
      current_plan: %{fragment: %ServerResources{}, processes: []},
      next_plan: %{shares: %{cpu: 0, ram: 0, net: %{}}, processes: []},
      acc: []
    }

    Enum.reduce(processes, keikaku, fn el, acc ->
      el = Changeset.change(el)

      case allocable_resources(el, resources) do
        [] ->
          Map.update!(acc, :acc, &([el| &1]))
        res ->
          shares = Changeset.get_field(el, :priority)
          net = Changeset.get_field(el, :network_id)

          acc
          |> update_in([:next_plan, :processes], &([{el, res}| &1]))
          |> update_in([:next_plan, :shares], &merge_share(&1, res, shares, net))
      end
    end)
  end

  defp allocable_resources(process, %{cpu: c, ram: r, net: n}) do
    net_id = Changeset.get_field(process, :network_id)
    net = Map.get(n, net_id, [dlk: 0, ulk: 0])

    # Returns a list of resource types that the server can't allocate for the
    # process so we can reject them from the resources the process ask
    # This is done so we can avoid trying to allocate resources a process can't
    # receive
    shouldnt =
      net
      |> Enum.to_list()
      |> Kernel.++([cpu: c, ram: r])
      |> Enum.filter_map(fn {_, v} -> v == 0 end, &elem(&1, 0))

    Process.can_allocate(process) -- shouldnt
  end

  @spec execute_step(t, ServerResources.t) :: t
  defp execute_step(plan = %{current_plan: %{fragment: f, processes: [{p0, r}| t]}}, resources) do
    shares = Changeset.get_field(p0, :priority)
    net_id = Changeset.get_field(p0, :network_id)

    allocate =
      f.net
      |> Map.get(net_id, %{})
      |> Enum.into(%{cpu: f.cpu, ram: f.ram}) # Prepare a map with resources that the process might want
      |> Map.take(r) # Filter out those that it didn't request
      |> Enum.map(fn {k, v} -> {k, v * shares} end)
      |> :maps.from_list()

    p1 = Process.allocate(p0, allocate)

    allo0 = Changeset.get_field(p0, :allocated)
    allo1 = Changeset.get_field(p1, :allocated)

    if allo0 == allo1 do
      # Nothing was changed, so this process won't receive any more allocation
      plan
      |> put_in([:current_plan, :processes], t)
      |> Map.update!(:acc, &([p0| &1]))
      |> execute_step(resources)
    else
      can_allocate = Process.can_allocate(p1)

      res_diff = Resources.sub(allo1, allo0)
      resources = %{resources|
        cpu: resources.cpu - res_diff.cpu,
        ram: resources.ram - res_diff.ram,
        net: case resources.net do
          n = %{^net_id => %{dlk: d1, ulk: u1}} ->
            Map.put(n, net_id, %{dlk: d1 - res_diff.dlk, ulk: u1 - res_diff.ulk})
          n ->
            n
        end
      }

      plan
      |> put_in([:current_plan, :processes], t)
      |> update_in([:next_plan, :processes], &([{p1, can_allocate}| &1]))
      |> update_in([:next_plan, :shares], &merge_share(&1, can_allocate, shares, net_id))
      |> execute_step(resources)
    end
  end

  defp execute_step(p = %{current_plan: %{processes: []}, next_plan: %{processes: []}}, _) do
    p
  end

  defp execute_step(plan = %{current_plan: %{processes: []}, next_plan: np}, resources) do
    %{processes: p, shares: s} = np

    # TODO: Maybe, instead of storing the shares the process asks for, just
    # store the process prio and what it is requesting, then, at this step,
    # filter out the requests that can't be completed because the resource
    # is all used (so we can save a few computations) and use the lowest common
    # denominator of the priority of the rest of processes to allocate more
    # properly the total amount of resources possible

    f = %ServerResources{
      cpu: s.cpu > 0 && div(resources.cpu, s.cpu) || 0,
      ram: s.ram > 0 && div(resources.ram, s.ram) || 0,
      net:
        resources.net
        |> Map.take(Map.keys(s.net))
        |> Enum.map(fn {k, %{dlk: d, ulk: u}} ->
          d2 = s.net[k].dlk
          u2 = s.net[u].ulk

          v2 = %{
            dlk: d2 > 0 && div(d, d2) || 0,
            ulk: u2 > 0 && div(u, u2) || 0
          }

          {k, v2}
        end)
        |> :maps.from_list()
    }

    # Let's simply update it to avoid forgetting we should keep the acc :joy:
    plan = %{plan|
      current_plan: %{processes: p, fragment: f},
      next_plan: %{shares: %{cpu: 0, ram: 0, net: %{}}, processes: []}
    }

    execute_step(plan, resources)
  end

  @spec merge_share(shares_plan, [:cpu | :ram | :dlk | :ulk], non_neg_integer, network_id) :: shares_plan
  defp merge_share(s, res, prio, net) do
    Enum.reduce(res, s, fn
      :cpu, acc = %{cpu: xs} ->
        %{acc| cpu: xs + prio}
      :ram, acc = %{ram: xs} ->
        %{acc| ram: xs + prio}
      link, acc = %{net: n} when link in [:ulk, :dlk] ->
        n2 =
          n
          |> Map.put_new(net, %{dlk: 0, ulk: 0})
          |> update_in([net, link], &(&1 + prio))

        %{acc| net: n2}
    end)
  end
end