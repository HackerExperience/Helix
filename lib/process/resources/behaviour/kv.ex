defmodule Helix.Process.Resources.Behaviour.KV do

  import Helix.Process.Resources

  def generate_behaviour(name, args) do
    quote location: :keep do

      alias Helix.Process.Resources.Utils, as: ResourceUtils

      @behaviour Helix.Process.Resources.Behaviour

      @name unquote(name)
      @key Keyword.fetch!(unquote(args), :key)

      def map(resource, function) do
        Enum.reduce(resource, %{}, fn {key, value}, acc ->
          new_value = function.(value)

          %{}
          |> Map.put(key, new_value)
          |> Map.merge(acc)
        end)
      end

      def reduce(resource, initial, function) do
        Enum.reduce(resource, initial, fn {key, value}, acc ->
          function.(acc, value)
        end)
      end

      def build([%{}]),
        do: %{}
      def build(entries) do
        Enum.reduce(entries, %{}, fn {key, value}, acc ->

          %{}
          |> Map.put(key, ResourceUtils.ensure_float(value))
          |> Map.merge(acc)
        end)
      end

      def initial,
        do: build([])

      def op_map(a, b, fun) do
        keys = get_keys(a, b)

        Map.merge(a, Map.take(b, keys), fn _, v1, v2 ->
          fun.(v1, v2)
        end)
      end

      sum(a, b) do
        op_map(a, b, &Kernel.+/2)
      end

      sub(a, b) do
        op_map(a, b, &Kernel.-/2)
      end

      mul(a, b) do
        op_map(a, b, &Kernel.*/2)
      end

      div(a, b) do
        op_map(a, b, &safe_div/2)
      end

      def completed?(processed, objective) do
        Enum.reduce(processed, %{}, fn {key, value}, acc ->
          # If the corresponding objective is `nil`, then by definition this
          # resource is completed
          result =
            if objective[key] do
              value > objective[key]
            else
              true
            end

          %{}
          |> Map.put(key, result)
          |> Map.merge(acc)
        end)
      end

      defp can_allocate?(%{processed: nil}, _),
        do: true
      defp can_allocate?(%{processed: processed, objective: objective}, key) do
        value_objective = objective[@name][key]
        value_processed = processed[@name][key]

        # Convert `nil` and `%{}` to `0.0`
        value_objective = is_number(value_objective) && value_objective || 0.0
        value_processed = is_number(value_processed) && value_processed || 0.0

        value_objective > value_processed
      end

      defp safe_div(dividend, divisor) when divisor > 0,
        do: dividend / divisor
      defp safe_div(_, 0.0),
        do: initial()
      defp safe_div(_, 0),
        do: initial()

      get_shares(process = %{priority: priority, dynamic: dynamic}) do
        with \
          true <- @name in dynamic,
          key = get_key(process),
          true <- key != nil,
          true <- can_allocate?(process, key)
        do
          Map.put(%{}, key, priority)
        else
          _ ->
            initial()
        end
      end

      resource_per_share(resources, shares) do
        keys = get_keys(resources, shares)

        # If there are fields defined on `resources` which are not on `shares`,
        # then we must "fill" `shares` with zero, since this means that the
        # allocator is not supposed to add any share to it. If we don't, once
        # we call `div/2` both maps will be merged, and no div operation would
        # be performed on `resources`.
        # TL;DR: Make sure we multiply by zero when we have no shares.
        shares =
          Enum.reduce(keys, shares, fn key, acc ->
            Map.put_new(acc, key, 0)
          end)

        __MODULE__.div(resources, shares)
      end

      allocate_static(process = %{static: static, state: state}) do
        alloc =
          static
          |> Map.get(state, %{})
          |> Map.get(@name, 0)

        case get_key(process) do
          nil ->
            initial()

          key ->
            Map.put(%{}, key, alloc)
        end
      end

      allocate_dynamic(shares, res_per_share, %{dynamic: dynamic}) do
        # TODO: Test if, by merging the operations into `map`, this is still
        # needed
        shares =
          Enum.reduce(get_keys(shares, res_per_share), shares, fn key, acc ->
            Map.put_new(acc, key, 0)
          end)

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
        false  # TODO
      end

      defp get_key(process),
        do: Map.fetch!(process, @key)

      defp get_keys(a, b) do
        Enum.uniq(Map.keys(a) ++ Map.keys(b))
      end
    end
  end
end
