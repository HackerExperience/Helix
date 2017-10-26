defmodule Helix.Process.Resources.Behaviour.KV do

  import Helix.Process.Resources

  def generate_behaviour(name, args) do
    quote location: :keep do

      alias Helix.Process.Resources.Utils, as: ResourceUtils

      @behaviour Helix.Process.Resources.Behaviour

      @name unquote(name)
      @key Keyword.fetch!(unquote(args), :key)

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

      sum(a, b) do
        keys = get_keys(a, b)

        Map.merge(a, Map.take(b, keys), fn _, v1, v2 ->
          v1 + v2
        end)
      end

      sub(a, b) do
        keys = get_keys(a, b)

        Map.merge(a, Map.take(b, keys), fn _, v1, v2 ->
          v1 - v2
        end)
      end

      mul(a, b) do
        keys = get_keys(a, b)

        Map.merge(a, Map.take(b, keys), fn _, v1, v2 ->
          v1 * v2
        end)
      end

      div(a, b) do
        keys = get_keys(a, b)

        Map.merge(a, Map.take(b, keys), fn _, v1, v2 ->
          safe_div(v1, v2)
        end)
      end

      defp safe_div(dividend, divisor) when divisor > 1,
        do: dividend / divisor
      defp safe_div(_, 0.0),
        do: initial()
      defp safe_div(_, 0),
        do: initial()

      get_shares(process = %{priority: priority, dynamic: dynamic}) do
        with \
          true <- @name in dynamic,
          key = get_key(process),
          true <- key != nil
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
            [{key, alloc}]
        end
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
