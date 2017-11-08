# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
# credo:disable-for-this-file Credo.Check.Refactor.LongQuoteBlocks
defmodule Helix.Process.Resources.Behaviour.Default do
  @moduledoc """
  The `DefaultBehaviour` of a TOP resource is the simpler form of a resource,
  which is used when dealing with raw numbers (floats) directly. Examples of
  DefaultBehaviours are CPU and RAM. A CPU is represented by a unit in MHz,
  while RAM is represented by its total in MB or KB.
  """

  import Helix.Process.Resources

  def generate_behaviour(name, args) do
    quote location: :keep do

      alias Helix.Process.Model.Process
      alias Helix.Process.Model.TOP
      alias Helix.Process.Resources.Utils, as: ResourceUtils

      @behaviour Helix.Process.Resources.Behaviour

      @name unquote(name)
      @formatter unquote(args)[:formatter] || &__MODULE__.default_formatter/1
      @mirror unquote(args)[:mirror] || @name

      @type t :: number
      @type initial :: t

      # Generic data manipulation

      @spec reduce(t, term, function) ::
        term
      def reduce(resource, initial, function),
        do: function.(initial, resource)

      @spec map(t, function) ::
        term
      def map(resource, function),
        do: function.(resource)

      @spec op_map(t, t, function) ::
        t
      def op_map(a, b, function),
        do: function.(a, b)

      # Creation & formatting of resource

      @spec build(number) ::
        t
      def build(value),
        do: value |> ResourceUtils.ensure_float()

      @spec initial ::
        initial
      def initial,
        do: build(0)

      @spec format(t) ::
        t
      def format(resource),
        do: @formatter.(resource)

      @spec default_formatter(t) ::
        t
      def default_formatter(v),
        do: v

      # Basic operations

      @spec sum(t, t) ::
        t
      sum(a, b) do
        a + b
      end

      @spec sub(t, t) ::
        t
      sub(a, b) do
        a - b
      end

      @spec div(t, t) ::
        t
      div(a, b) do
        ResourceUtils.safe_div(a, b, &initial/0)
      end

      @spec mul(t, t) ::
        t
      mul(a, b) do
        a * b
      end

      # Allocation logic

      @spec get_shares(Process.t) ::
        t
      get_shares(process = %{priority: priority}) do
        dynamic_res = Process.get_dynamic(process)

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

      @spec mirror ::
        Process.resource
      def mirror,
        do: @mirror

      @spec can_allocate?(Process.t) ::
        boolean
      defp can_allocate?(%{processed: nil}),
        do: true
      defp can_allocate?(%{processed: processed, objective: objective}),
        do: Map.fetch!(objective, @name) >= Map.get(processed, @name, 0)

      @spec resource_per_share(t, t) ::
        t
      resource_per_share(resources, shares) do
        res_per_share = __MODULE__.div(resources, shares)

        res_per_share >= 0 && res_per_share || 0.0
      end

      @spec allocate_static(Process.t) ::
        t
      allocate_static(%{local?: false}) do
        initial()
      end

      allocate_static(%{static: static, state: state}) do
        state =
          if state == :waiting_allocation do
            :running
          else
            state
          end

        static
        |> Map.get(state, %{})
        |> Map.get(@name, initial())
      end

      @spec allocate_dynamic(t, t, Process.t) ::
        t
      allocate_dynamic(shares, res_per_share, process) do
        dynamic = Process.get_dynamic(process)

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
        boolean
      def completed?(processed, objective),
        do: processed >= objective

      @spec overflow?(t, [TOP.Allocator.allocated_process]) ::
        {true, heaviest :: Process.t}
        | false
      def overflow?(res, allocated_processes) do
        # Due to rounding errors, we may have a "valid overflow" of a few units
        if res < -1 do
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
            Map.fetch!(resources, @name)
          end)
        |> List.last()
        |> elem(0)
      end
    end
  end
end
