defmodule Helix.Process.Resources.Behaviour.Default do

  import Helix.Process.Resources

  def generate_behaviour(name, _args) do
    quote location: :keep do

      alias Helix.Process.Resources.Utils, as: ResourceUtils

      @behaviour Helix.Process.Resources.Behaviour

      @name unquote(name)

      def build(value),
        do: value |> ResourceUtils.ensure_float()

      def initial,
        do: build(0)

      sum(a, b) do
        a + b
      end

      sub(a, b) do
        a - b
      end

      div(a, b) do
        safe_div(a, b)
      end

      mul(a, b) do
        a * b
      end

      defp safe_div(dividend, divisor) when divisor > 1,
        do: dividend / divisor
      defp safe_div(_, 0.0),
        do: 0
      defp save_div(_, 0),
        do: 0

      get_shares(%{priority: priority, dynamic: dynamic_res}) do
        if @name in dynamic_res do
          priority
        else
          initial()
        end
      end

      resource_per_share(resources, shares) do
        __MODULE__.div(resources, shares)
      end

      allocate_static(%{static: static, state: state}) do
        static
        |> Map.get(state, %{})
        |> Map.get(@name, 0)
      end

      allocate_dynamic(shares, res_per_share, %{dynamic: dynamic}) do
        if @name in dynamic do
          mul(shares, res_per_share)
        else
          initial()
        end
      end

      allocate(dynamic_alloc, static_alloc) do
        sum(dynamic_alloc, static_alloc)
      end

      def overflow?(res, allocated_processes) do
        # Due to rounding errors, we may have a "valid overflow" of a few units
        if res < -1 do
          {true, find_heaviest(allocated_processes)}
        else
          false
        end
      end

      defp find_heaviest(allocated_processes) do
        allocated_processes
        |> Enum.sort_by(fn {process, resources} ->
            Map.fetch!(resources, @name)
          end)
        |> List.last()
        |> elem(0)
      end
    end
  end
end
