defmodule Helix.Test.Process.Setup.TOP do

  alias Helix.Process.Model.Process

  alias HELL.TestHelper.Random
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Process.Helper.TOP, as: TOPHelper

  @internet_id NetworkHelper.internet_id()

  def fake_process(opts \\ []) do
    num_procs = Keyword.get(opts, :total, 1)
    network_id = Keyword.get(opts, :network_id, @internet_id)

    res_usage =
      TOPHelper.Resources.split_usage(
        opts[:total_resources], num_procs, network_id
      )

    1..num_procs
    |> Enum.map(fn _ ->
      gen_fake_process(opts, res_usage)
    end)
  end

  defp gen_fake_process(opts, res_usage) do
    priority = Keyword.get(opts, :priority, 3)
    state = Keyword.get(opts, :state, :running)

    network_id = Keyword.get(opts, :network_id, @internet_id)

    l_dynamic = Keyword.get(opts, :l_dynamic, [:cpu, :ram])
    r_dynamic = Keyword.get(opts, :r_dynamic, [])

    static =
      if opts[:static] do
        opts[:static]
      else
        TOPHelper.Resources.calculate_static(opts, res_usage)
      end

    processed = Keyword.get(opts, :processed, nil)
    objective = Keyword.get(opts, :objective, TOPHelper.Resources.objective())
    next_allocation = Keyword.get(opts, :next_allocation, nil)

    l_limit = Keyword.get(opts, :l_limit, %{})
    r_limit = Keyword.get(opts, :r_limit, %{})

    l_reserved = Keyword.get(opts, :l_reserved, %{})
    r_reserved = Keyword.get(opts, :r_reserved, %{})

    creation_time = Keyword.get(opts, :creation_time, DateTime.utc_now())
    last_checkpoint_time = Keyword.get(opts, :last_checkpoint_time, nil)

    gateway_id = Keyword.get(opts, :gateway_id, :gateway)
    target_id = Keyword.get(opts, :target_id, :target)
    local? = Keyword.get(opts, :local?, nil)

    initial = Process.Resources.initial()
    l_allocated = Keyword.get(opts, :l_allocated, initial)
    r_allocated = Keyword.get(opts, :r_allocated, initial)

    data = Keyword.get(opts, :data, nil)

    %Process{
      process_id: Random.number(),
      gateway_id: gateway_id,
      target_id: target_id,
      data: data,
      objective: objective,
      processed: processed,
      next_allocation: next_allocation,
      priority: priority,
      state: state,
      static: static,
      l_dynamic: l_dynamic,
      r_dynamic: r_dynamic,
      l_limit: l_limit,
      r_limit: r_limit,
      l_reserved: l_reserved,
      r_reserved: r_reserved,
      l_allocated: l_allocated,
      r_allocated: r_allocated,
      network_id: network_id,
      creation_time: creation_time,
      last_checkpoint_time: last_checkpoint_time,
      local?: local?
    }
  end
end
