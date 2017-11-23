# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule Helix.Server.Component.Spec.Flow do

  import HELL.Macros.Utils

  alias HELL.Utils

  defmacro __using__(_) do
    quote do

      import unquote(__MODULE__)

      # List of all declared specs ([:hdd, :ram, :cpu, :nic, :usb])
      Module.register_attribute(__MODULE__, :specs, accumulate: true)

      # Notice more attributes will be registered down the line. Those will
      # contain the specific `spec_ids` of each `spec`, and will have the name
      # `specs_#{spec_name}`. Example: `specs_cpu` contains all CPU specs.

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do

      unquote(specs_getter(__CALLER__))
      unquote(specs_functions())

    end
  end

  defp specs_getter(caller) do
    specs = Module.get_attribute(caller.module, :specs)

    # HACK: Not sure how to create the following AST using Elixir's quotes and
    # unquotes. Basically, what the cryptic lines below generate are:
    #
    # def get_#{spec_name} do
    #   @specs_#{spec_name}
    # end
    #
    # where `spec_name` is one of [:hdd, :cpu, :ram...]
    # and `@specs_#{spec_name}` is the module attribute that contains a list of
    # all spec_ids declared for that specific spec.
    for spec <- specs do
      fun_name = :"get_#{spec}"
      attr_name = Utils.concat_atom(:specs_, spec)

      {:def, [context: __MODULE__, import: Kernel],
        [{fun_name, [context: __MODULE__], __MODULE__},
          [do: {:@, [context: __MODULE__, import: Kernel],
            [{attr_name, [context: __MODULE__], __MODULE__}]}]]}
    end
  end

  defp specs_functions do
    quote do

      def create_custom(spec),
        do: dispatch(spec.component_type, :create_custom, [spec.data])

      def format_custom(component) do
        formatted? =
          Enum.reduce(Map.keys(component.custom), true, fn key, acc ->
            is_atom(key) && acc || false
          end)

        if formatted? do
          component.custom
        else
          dispatch(component.type, :format_custom, [component.custom])
        end
      end

      def get_initial(type),
        do: dispatch(type, :get_initial, [])

      def dispatch(type, fun, args) do
        component_module = type |> Utils.upcase_atom()

        module =
          __MODULE__
          |> Utils.concat_atom(".")
          |> Utils.concat_atom(component_module)

        apply(module, fun, args)
      end

      def fetch(spec_id) do
        spec_id = Utils.downcase_atom(spec_id)
        spec_str = Atom.to_string(spec_id)

        type =
          case spec_str do
            "cpu_" <> _ ->
              :cpu

            "ram_" <> _ ->
              :ram

            "hdd_" <> _ ->
              :hdd

            "nic_" <> _ ->
              :nic

            "mobo_" <> _ ->
              :mobo
          end

        dispatch(type, :"spec_#{spec_id}", [])
      end

      def all_specs do
        Enum.map(@specs, fn spec ->
          __MODULE__
          |> apply(:"get_#{spec}", [])
          |> List.flatten()
        end)
      end

      # @spec generate_specs() ::
        # %{
        #   cpu: [spec :: term],
        #   hdd: [spec :: term]
        # }
      def generate_specs do

        Enum.reduce(@specs, %{}, fn spec, acc ->
          spec_name = Utils.upcase_atom(spec)

          spec_module =
            __MODULE__
            |> Utils.concat_atom(".")
            |> Utils.concat_atom(spec_name)

          ids =
            __MODULE__
            |> apply(:"get_#{spec}", [])
            |> List.flatten()

          generated_specs =
            Enum.map(ids, fn spec_id ->
              spec_id_name = Utils.downcase_atom(spec_id)

              apply(spec_module, :"spec_#{spec_id_name}", [])
            end)

          %{}
          |> Map.put(spec, generated_specs)
          |> Map.merge(acc)
        end)
      end
    end
  end

  defmacro specs(name, do: block) do
    # Stores at compile-time the information about which specs are declared
    spec_name = atomize_module_name(name)
    spec_attr = Utils.concat_atom(:specs_, spec_name)

    quote do

      # Notify Component.Specs that the spec #{name} is declared
      Module.put_attribute(
        unquote(__CALLER__.module),
        :specs,
        unquote(spec_name)
      )

      # We'll create the @specs_#{spec_name} attribute at Component.Specs root
      Module.register_attribute(
        unquote(__CALLER__.module),
        unquote(spec_attr),
        accumulate: true
      )

      defmodule unquote(name) do

        unquote(block)

        def fetch(spec_id) do
          spec_id_name = spec_id

          # TODO Raises if function is not found. Desired?
          apply(__MODULE__, :"spec_#{spec_id_name}", [])
        end

        def get_initial,
          do: @initial
      end
    end
  end

  defmacro spec(name, do: block) do
    name = Utils.downcase_atom(name)
    spec_name = atomize_module_name(name)
    parent_spec = get_current_spec(__CALLER__.module)
    specs_module = get_parent_module(__CALLER__.module)

    spec_attr = Utils.concat_atom(:specs_, parent_spec)

    quote location: :keep do

      # Notifies `Component.Spec` that `spec_name` is declared
      Module.put_attribute(
        unquote(specs_module),
        unquote(spec_attr),
        unquote(spec_name)
      )

      def unquote(:"spec_#{name}")() do
        data =
          unquote(block)
          |> Map.put(:spec_id, unquote(spec_name))
          |> Map.put(:component_type, unquote(parent_spec))

        unquote(__CALLER__.module).validate_spec(data)
        && data
        || raise "Invalid spec #{inspect data} for #{unquote(parent_spec)}"
      end
    end
  end

  defmacro slots(slots) do
    quote do
      unquote(slots) |> Enum.sort_by(&1 > &2)
    end
  end

  defmacro validate_has_keys(map, keys) do
    quote do
      Enum.reduce(unquote(keys), true, fn key, acc ->
        Map.has_key?(unquote(map), key) && acc || false
      end)
    end
  end

  defp get_current_spec(module) do
    module
    |> Module.split()
    |> Enum.take(-1)
    |> List.first()
    |> String.downcase()
    |> String.to_atom()
  end
end
