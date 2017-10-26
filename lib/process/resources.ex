defmodule Helix.Process.Resources do

  alias HELL.Utils

  defmacro __using__(_) do
    quote do

      import Helix.Process.Resources


      Module.register_attribute(
        __MODULE__,
        :resources,
        accumulate: true,
        persist: true
      )

      @before_compile unquote(__MODULE__)

    end
  end

  defmacro __before_compile__(_) do
    quote do

      # Maps the resource (name) to its module.
      @res_modules (
        Enum.reduce(@resources, %{}, fn resource, acc ->

          %{}
          |> Map.put(resource, get_resource_module(__MODULE__, resource))
          |> Map.merge(acc)
        end)
      )

      def sum(res_a, res_b),
        do: dispatch_merge(:sum, res_a, res_b)

      def sub(res_a, res_b),
        do: dispatch_merge(:sub, res_a, res_b)

      def mul(res_a, res_b),
        do: dispatch_merge(:mul, res_a, res_b)

      def div(res_a, res_b),
        do: dispatch_merge(:div, res_a, res_b)

      def get_shares(process),
        do: dispatch_create :get_shares, [process]

      def resource_per_share(resources, shares),
        do: dispatch_merge :resource_per_share, resources, shares

      def allocate_static(process),
        do: dispatch_create :allocate_static, [process]

      def allocate_dynamic(shares, res_per_share, process),
        do: dispatch_merge :allocate_dynamic, shares, res_per_share, [process]

      def allocate(dynamic_alloc, static_alloc),
        do: dispatch_merge :allocate, dynamic_alloc, static_alloc

      def initial,
        do: dispatch_create :initial

      def overflow?(resources, processes),
        do: dispatch(:overflow?, resources, [processes])
    end
  end

  defmacro dispatch(method, resources, params \\ quote(do: [])) do
    quote do
      Enum.reduce(@resources, %{}, fn resource_name, acc ->

        resource = Map.fetch!(unquote(resources), resource_name)
        params = [resource] ++ unquote(params)

        result = call_resource(resource_name, unquote(method), params)

        %{}
        |> Map.put(resource_name, result)
        |> Map.merge(acc)
      end)
    end
  end

  defmacro dispatch_merge(method, res_a, res_b, params \\ quote(do: [])) do
    quote do
      unquote(res_a)
      |> Map.merge(Map.take(unquote(res_b), @resources), fn resource, v1, v2 ->
        call_resource(resource, unquote(method), [v1, v2] ++ unquote(params))
      end)
    end
  end

  defmacro dispatch_create(method, params \\ quote(do: [])) do
    quote do
      Enum.reduce(@resources, %{}, fn resource, acc ->
        result = call_resource(resource, unquote(method), unquote(params))

        %{}
        |> Map.put(resource, result)
        |> Map.merge(acc)
      end)
    end
  end

  defmacro call_resource(resource, method, params) do
    quote do
      module = Map.get(@res_modules, unquote(resource))
      apply(module, unquote(method), unquote(params))
    end
  end

  def get_resource_module(caller, resource) do
    module_name =
      resource
      |> Atom.to_string()
      |> String.upcase()
      |> String.to_atom()

    Module.concat(caller, module_name)
  end

  defmacro resources(name, do: block) do
    quote location: :keep do

      defmodule unquote(name) do

        @name unquote(name)

        use Helix.Process.Resources

        unquote(block)
      end

    end
  end

  defmacro resource(name, opts) do
    opts = Macro.expand(opts, __CALLER__)

    resource_name = get_resource_name(name)

    args =
      if opts[:behaviour] do
        behaviour_block =
          opts[:behaviour]
          |> Macro.expand(__CALLER__)
          |> apply(:generate_behaviour, [resource_name, opts])

        [behaviour: behaviour_block]
      else
        [do: opts[:do]]
      end

    do_resource(name, resource_name, args)
  end

  defp do_resource(module_name, resource_name, do: block) do
    quote location: :keep do
      Module.put_attribute(__MODULE__, :resources, unquote(resource_name))

      defmodule unquote(module_name) do

        unquote(block)
      end

    end
  end

  defp do_resource(module_name, resource_name, behaviour: behaviour_block) do
    quote location: :keep do
      resource unquote(module_name) do
        unquote(behaviour_block)
      end
    end
  end

  defp get_resource_name({_, _, [name]}),
    do: name |> Atom.to_string() |> String.downcase() |> String.to_atom()

  @operations [:sum, :sub, :mul, :div]
  @methods [
    {:get_shares, 1},
    {:resource_per_share, 2},
    {:allocate_static, 1},
    {:allocate_dynamic, 3},
    {:allocate, 2}
  ]

  for op <- @operations do

    defmacro unquote(op)(a, b, do: block) do
      op = unquote(op)

      quote location: :keep do

        def unquote(op)(unquote(a), unquote(b)) do
          unquote(block)
          # |> ensure_float()
          |> build()
        end

      end
    end
  end

  for {method, arity} <- @methods do

    params =
      1..arity
      |> Enum.map(fn i ->
        name = Utils.concat_atom(:arg, Integer.to_string(i))
        Macro.var(name, nil)
      end)

    defmacro unquote(method)(unquote_splicing(params), do: block) do
      method = unquote(method)
      params = unquote(params)

      quote location: :keep do

        def unquote(method)(unquote_splicing(params)) do
          unquote(block)
          |> build()
        end

      end
    end
  end
end
