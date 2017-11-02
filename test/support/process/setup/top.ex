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
    dynamic = Keyword.get(opts, :dynamic, [:cpu, :ram])

    static =
      if opts[:static] do
        opts[:static]
      else
        TOPHelper.Resources.calculate_static(opts, res_usage)
      end

    processed = Keyword.get(opts, :processed, nil)
    objective = Keyword.get(opts, :objective, TOPHelper.Resources.objective())
    allocated = Keyword.get(opts, :allocated, nil)
    next_allocation = Keyword.get(opts, :next_allocation, nil)
    limit = Keyword.get(opts, :limit, %{})

    creation_time = Keyword.get(opts, :creation_time, DateTime.utc_now())
    last_checkpoint_time = Keyword.get(opts, :last_checkpoint_time, nil)

    %Process{
      process_id: Random.number(),
      objective: objective,
      processed: processed,
      allocated: allocated,
      next_allocation: next_allocation,
      priority: priority,
      state: state,
      static: static,
      dynamic: dynamic,
      limit: limit,
      network_id: network_id,
      creation_time: creation_time,
      last_checkpoint_time: last_checkpoint_time
    }
  end
end
