defmodule Helix.Test.Process.Helper.TOP.Resources do

  alias HELL.TestHelper.Random

  def split_usage(total_resources, num_procs, network_id \\ nil) do
    if total_resources do
      ulk = Map.get(total_resources.ulk, network_id)
      dlk = Map.get(total_resources.dlk, network_id)

      {
        div(total_resources.cpu, num_procs + 1),
        div(total_resources.ram, num_procs + 1),
        ulk && div(ulk, num_procs + 1) || 0,
        dlk && div(dlk, num_procs + 1) || 0,
      }
    else
      {10_000, 10_000, 10_000, 10_000}
    end
  end

  def calculate_static(opts, {max_cpu, max_ram, max_ulk, max_dlk}) do
    static_cpu = Keyword.get(opts, :static_cpu, Random.number(0..max_cpu))
    static_ram = Keyword.get(opts, :static_ram, Random.number(0..max_ram))
    static_ulk = Keyword.get(opts, :static_ulk, Random.number(0..max_ulk))
    static_dlk = Keyword.get(opts, :static_dlk, Random.number(0..max_dlk))

    paused_static =
      if Random.number(0..1) == 1 do
        %{
          cpu: Random.number(0..1) == 1 && div(static_cpu, 2) || 0,
          ram: Random.number(0..1) == 1 && div(static_ram, 2) || 0,
          dlk: Random.number(0..1) == 1 && div(static_dlk, 2) || 0,
          ulk: Random.number(0..1) == 1 && div(static_ulk, 2) || 0
        }
      else
        %{}
      end

    running_static = %{
      cpu: static_cpu,
      ram: static_ram,
      dlk: static_dlk,
      ulk: static_ulk
    }

    %{
      running: running_static,
      paused: paused_static
    }
  end

  def objective(opts \\ []) do
    if not is_nil(opts[:dlk]) or not is_nil(opts[:ulk]) do
      opts[:network_id] || raise "I need a network_id too!"
    end

    # %{} (empty) if not defined
    ulk = opts[:ulk] && Map.put(%{}, opts[:network_id], opts[:ulk]) || %{}
    dlk = opts[:dlk] && Map.put(%{}, opts[:network_id], opts[:dlk]) || %{}

    %{
      cpu: opts[:cpu] || 999_999,
      ram: opts[:ram] || 999_999,
      dlk: dlk,
      ulk: ulk
    }
  end

  def random_static(_opts \\ []) do
    # Guaranteed to be random
    %{
      paused: %{ram: 10},
      running: %{ram: 20}
    }
  end
end
