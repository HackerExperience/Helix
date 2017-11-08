defmodule Helix.Process.Resources.Behaviour.KV do

  import Helix.Process.Resources

  def generate_behaviour(name, args) do
    quote location: :keep do

      formatter = unquote(args)[:formatter]

      alias Helix.Process.Model.Process
      alias Helix.Process.Model.TOP
      alias Helix.Process.Resources.Utils, as: ResourceUtils

      @behaviour Helix.Process.Resources.Behaviour

      @name unquote(name)
      @key Keyword.fetch!(unquote(args), :key)
      @formatter unquote(args)[:formatter] || &__MODULE__.default_formatter/2
      @mirror unquote(args)[:mirror] || @name

      @type key :: term
      @type value :: number

      @type t :: %{key => value} | %{}
      @type initial :: %{}

      @type map_t(type) :: %{key => type} | %{}

      # Generic data manipulation

      @spec map(t, function) ::
        map_t(term)
      def map(resource, function) do
        Enum.reduce(resource, %{}, fn {key, value}, acc ->
          new_value = function.(value)

          %{}
          |> Map.put(key, new_value)
          |> Map.merge(acc)
        end)
      end

      @spec reduce(t, term, function) ::
        term
      def reduce(resource, initial, function) do
        Enum.reduce(resource, initial, fn {key, value}, acc ->
          function.(acc, value)
        end)
      end

      @spec op_map(t, t, function) ::
        t
      def op_map(a, b, fun) do
        keys = get_keys(a, b)

        Map.merge(a, Map.take(b, keys), fn _, v1, v2 ->
          fun.(v1, v2)
        end)
      end

      # Creation & formatting of resource

      @spec build(t | [t]) ::
        t
      def build(entries) do
        Enum.reduce(entries, %{}, fn {key, value}, acc ->

          %{}
          |> Map.put(key, ResourceUtils.ensure_float(value))
          |> Map.merge(acc)
        end)
      end

      @spec initial ::
        initial
      def initial,
        do: build([])

      @spec format(map_t(term)) ::
        t
      def format(resource) do
        Enum.reduce(resource, %{}, fn {key, value}, acc ->
          {k, v} = @formatter.(key, value)

          %{}
          |> Map.put(k, v)
          |> Map.merge(acc)
        end)
      end

      @spec default_formatter(term, term) ::
        {key, number}
      def default_formatter(k, v),
        do: {k, v}

      # Basic operations

      @spec sum(t, t) ::
        t
      sum(a, b) do
        op_map(a, b, &Kernel.+/2)
      end

      @spec sub(t, t) ::
        t
      sub(a, b) do
        # Ensure missing elements (exist on `b` but not on `a`) are filled as 0.
        # a = fill_missing(a, b)

        op_map(a, b, &Kernel.-/2)
      end

      @spec mul(t, t) ::
        t
      mul(a, b) do
        op_map(a, b, &Kernel.*/2)
      end

      @spec div(t, t) ::
        t
      div(a, b) do
        op_map(a, b, fn a, b -> ResourceUtils.safe_div(a, b, &initial/0) end)
      end

      # Allocation logic

      @spec fill_missing(t, t, value) ::
        t
      defp fill_missing(a, b, value \\ 0) do
        Enum.reduce(get_keys(a, b), a, fn key, acc ->
          Map.put_new(acc, key, value)
        end)
      end

      @spec get_shares(Process.t) ::
        t
      get_shares(process = %{priority: priority}) do
        dynamic = Process.get_dynamic(process)

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

      @spec mirror ::
        Process.resource
      def mirror,
        do: @mirror

      @spec can_allocate?(Process.t, key) ::
        boolean
      defp can_allocate?(%{processed: nil}, _),
        do: true
      defp can_allocate?(%{local?: false}, _),
        do: true
      defp can_allocate?(%{processed: processed, objective: objective}, key) do
        value_objective = objective[@name][key]
        value_processed = processed[@name][key]

        # Convert `nil` and `%{}` to `0.0`
        value_objective = is_number(value_objective) && value_objective || 0.0
        value_processed = is_number(value_processed) && value_processed || 0.0

        value_objective > value_processed
      end

      @spec resource_per_share(t, t) ::
        t
      resource_per_share(resources, shares) do
        # If there are fields defined on `resources` which are not on `shares`,
        # then we must "fill" `shares` with zero, since this means that the
        # allocator is not supposed to add any share to it. If we don't, once
        # we call `div/2` both maps will be merged, and no div operation would
        # be performed on `resources`.
        # TL;DR: Make sure we multiply by zero when we have no shares.
        shares = fill_missing(shares, resources)

        res_per_share = __MODULE__.div(resources, shares)

        # Ensure we do not return any negative or invalid number
        map(res_per_share, fn v -> is_number(v) && v >= 0 && v || 0.0 end)
      end

      # At least currently, only local process may allocate static resources
      # This means that e.g. a FileDownload may consume RAM on the local server
      # but none on the remote one.
      @spec allocate_static(Process.t) ::
        t
      allocate_static(%{local?: false}) do
        initial()
      end

      allocate_static(process = %{static: static, state: state}) do
        state =
          if state == :waiting_allocation do
            :running
          else
            state
          end

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

      @spec allocate_dynamic(t, t, Process.t) ::
        t
      allocate_dynamic(shares, res_per_share, process) do
        dynamic = Process.get_dynamic(process)

        shares = fill_missing(shares, res_per_share)

        if @name in dynamic do
          mul(shares, res_per_share)
        else
          initial()
        end
      end

      @spec allocate(t, t) ::
        t
      allocate(dynamic_alloc, static_alloc) do
        sum(dynamic_alloc, static_alloc)
      end

      @spec completed?(t, t) ::
        t
      def completed?(processed, objective) do
        Enum.reduce(processed, %{}, fn {key, value}, acc ->
          # If the corresponding objective is `nil`, then by definition this
          # resource is completed
          result =
            if objective[key] do
              value >= objective[key]
            else
              true
            end

          %{}
          |> Map.put(key, result)
          |> Map.merge(acc)
        end)
      end

      @spec overflow?(t, [TOP.Allocator.allocated_process]) ::
        {true, heaviest :: Process.t}
        | false
      def overflow?(res, allocated_processes) do
        overflowed? =
          reduce(res, false, fn acc, val ->
            # Slack for rounding errors
            if val >= -1 do
              acc
            else
              true
            end
          end)

        if overflowed? do
          {true, find_heaviest(allocated_processes)}
        else
          false
        end
      end

      @spec find_heaviest([TOP.Allocator.allocated_process]) ::
        Process.t
      defp find_heaviest(allocated_processes) do
        allocated_processes
        |> Enum.sort_by(fn {process, resources} ->
          resources
          |> Map.fetch!(@name)
          |> Map.fetch!(get_key(process))
        end)
        |> List.last()
        |> elem(0)
      end

      @spec get_key(Process.t) ::
        key
      defp get_key(process),
        do: Map.fetch!(process, @key)

      @spec get_keys(t, t) ::
        [key]
      defp get_keys(a, b) do
        Enum.uniq(Map.keys(a) ++ Map.keys(b))
      end
    end
  end
end
