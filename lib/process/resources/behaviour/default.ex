defmodule Helix.Process.Resources.Behaviour.Default do

  import Helix.Process.Resources

  def generate_behaviour(name, args) do
    quote location: :keep do

      alias Helix.Process.Resources.Utils, as: ResourceUtils

      @behaviour Helix.Process.Resources.Behaviour

      @name unquote(name)
      @formatter unquote(args)[:formatter] || &__MODULE__.default_formatter/1

      # Generic data manipulation

      def reduce(resource, initial, function),
        do: function.(initial, resource)

      def map(resource, function),
        do: function.(resource)

      def op_map(a, b, function),
        do: function.(a, b)

      # Creation & formatting of resource

      def build(value),
        do: value |> ResourceUtils.ensure_float()

      def initial,
        do: build(0)

      def format(resource),
        do: @formatter.(resource)

      def default_formatter(v),
        do: v

      # Basic operations

      sum(a, b) do
        a + b
      end

      sub(a, b) do
        a - b
      end

      div(a, b) do
        ResourceUtils.safe_div(a, b, &initial/0)
      end

      mul(a, b) do
        a * b
      end

      # Allocation logic

      get_shares(process = %{priority: priority, dynamic: dynamic_res}) do
        with \
          true <- @name in dynamic_res,
          true <- can_allocate?(process)
        do
          priority
        else
          _ ->
            initial()
        end
      end

      defp can_allocate?(%{processed: nil}),
        do: true
      defp can_allocate?(%{processed: processed, objective: objective}),
        do: Map.fetch!(objective, @name) >= Map.get(processed, @name, 0)

      resource_per_share(resources, shares) do
        res_per_share = __MODULE__.div(resources, shares)

        res_per_share >= 0 && res_per_share || 0.0
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

      def completed?(processed, objective),
        do: processed >= objective

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
