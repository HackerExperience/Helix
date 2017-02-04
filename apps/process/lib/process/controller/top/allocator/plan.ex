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
      processes: [{process_id, [:cpu | :ram | :dlk | :ulk]}]
    },
    next_plan: %{
      shares: shares_plan,
      processes: [{process_id, [:cpu | :ram | :dlk | :ulk]}]
    }
  }

  @typep process_map :: %{process_id => process}

  defstruct [
    current_plan: %{
      fragment: %ServerResources{},
      processes: []
    },
    next_plan: %{
      shares: %{
        cpu: 0,
        ram: 0,
        net: %{}
      },
      processes: []
    }
  ]

  # TODO: Refactor and comment this shit

  @spec allocate([process], ServerResources.t) :: [Ecto.Changeset.t]
  def allocate(processes, resources) do
    process_map =
      processes
      # Coherces all structs into changesets to ensure we can easily use the
      # changeset functions
      |> Enum.map(&({&1.process_id, Changeset.change(&1)}))
      |> :maps.from_list()

    processes
    |> plan(resources)
    |> execute_step(process_map, resources)
    |> Map.values()
  end

  @spec plan([process], ServerResources.t) :: t
  defp plan(processes, resources) do
    Enum.reduce(processes, %__MODULE__{}, fn el, acc ->
      el = Changeset.change(el)

      case allocable_resources(el, resources) do
        [] ->
          acc
        res ->
          %{next_plan: %{processes: p, shares: s}} = acc
          shares = Changeset.get_field(el, :priority)
          net = Changeset.get_field(el, :network_id)
          process_id = Changeset.get_field(el, :process_id)

          plan = %{
            processes: [{process_id, res}| p],
            shares: merge_share(s, res, shares, net)
          }

          %{acc| next_plan: plan}
      end
    end)
  end

  defp allocable_resources(process, %{cpu: c, ram: r, net: n}) do
    net = Changeset.get_field(process, :network_id)
    n = n[net]

    no = n && Enum.filter_map(n, fn {_, v} -> v == 0 end, &elem(&1, 0)) || []
    no? = c == 0 && [:cpu| no] || no
    no! = r == 0 && [:ram| no?] || no?

    Process.can_allocate(process) -- no!
  end

  @spec execute_step(t, process_map, ServerResources.t) :: process_map
  defp execute_step(plan = %__MODULE__{current_plan: %{fragment: f, processes: [{p, r}| t]}}, processes, resources) do
    process = Map.fetch!(processes, p)
    shares = Changeset.get_field(process, :priority)
    net = Changeset.get_field(process, :network_id)

    allo1 = Changeset.get_field(process, :allocated)

    allocate =
      f.net
      |> Map.get(net, %{})
      |> Enum.into(Map.take(f, [:cpu, :ram]))
      |> Map.take(r)
      |> Enum.map(fn {k, v} -> {k, v * shares} end)
      |> :maps.from_list()

    process = Process.allocate(process, allocate)

    allo2 = Changeset.get_field(process, :allocated)

    if allo1 == allo2 do
      # Nothing was changed, so this process won't receive any more allocation
      plan = %{plan| current_plan: %{plan.current_plan| processes: t}}

      execute_step(plan, processes, resources)
    else
      can_allocate = Process.can_allocate(process)

      res_diff = Resources.sub(allo2, allo1)

      resources = %{resources|
        cpu: resources.cpu - res_diff.cpu,
        ram: resources.ram - res_diff.ram,
        net: case resources.net do
          n = %{^net => %{dlk: d1, ulk: u1}} ->
            Map.put(n, net, %{dlk: d1 - res_diff.dlk, ulk: u1 - res_diff.ulk})
          n ->
            n
        end
      }

      processes = Map.put(processes, p, process)

      plan = %{plan|
        current_plan: %{plan.current_plan|
          processes: t
        },
        next_plan:
          plan.next_plan
          |> Map.update!(:processes, &([{p, can_allocate}| &1]))
          |> Map.update!(:shares, &merge_share(&1, can_allocate, shares, net))
      }

      execute_step(plan, processes, resources)
    end
  end

  defp execute_step(%__MODULE__{current_plan: %{processes: []}, next_plan: %{processes: []}}, p, _) do
    p
  end

  defp execute_step(%__MODULE__{current_plan: %{processes: []}, next_plan: np}, processes, resources) do
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

    plan2 = %__MODULE__{current_plan: %{processes: p, fragment: f}}

    execute_step(plan2, processes, resources)
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