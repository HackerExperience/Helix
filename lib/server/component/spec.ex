defmodule Helix.Server.Component.Spec do

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

      use Ecto.Schema

      import Ecto.Changeset

      alias HELL.Constant

      unquote(specs_schema())
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
      def get_spec(spec) do
        # figure out the underlying spec (cpu, hdd, ...) and then dispatch
        :todo_spec
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
          spec_name =
            spec
            |> Atom.to_string()
            |> String.upcase()
            |> String.to_atom()

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
              spec_id_name =
                spec_id
                |> Atom.to_string()
                |> String.upcase()
                |> String.to_atom()

              apply(spec_module, :"spec_#{spec_id_name}", [])
            end)

          %{}
          |> Map.put(spec, generated_specs)
          |> Map.merge(acc)
        end)
      end
    end
  end

  defp specs_schema do
    quote location: :keep do

      @type id :: term

      @type t ::
        %__MODULE__{
          spec_id: id,
          component_type: component_type,
          spec: spec
        }

      @type spec :: %{
        :spec_id => String.t,
        :spec_type => String.t,
        :name => String.t,
        optional(atom) => any
      }

      @typep component_type :: Constant.t

      @creation_fields [:spec_id, :component_type, :spec]

      @primary_key false
      schema "component_specs" do

        field :spec_id, Constant,
          primary_key: true

        field :component_type, Constant

        field :spec, :map

      end

      def create_changeset(spec_id, component_type, spec) do
        params =
          %{
            spec_id: spec_id,
            component_type: component_type,
            spec: spec
          }

        %__MODULE__{}
        |> cast(params, @creation_fields)
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
          spec_id_name =
            spec_id
            |> Atom.to_string()
            |> String.upcase()
            |> String.to_atom()

          # TODO Raises if function is not found. Desired?
          apply(__MODULE__, :"spec_#{spec_id_name}", [])
        end
      end

    end
  end

  defmacro spec(name, do: block) do
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

        unquote(__CALLER__.module).validate_spec(data)
        && data
        || raise "Invalid spec #{inspect data} for #{unquote(parent_spec)}"
      end
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

defmodule Helix.Server.Component.Specs do

  use Helix.Server.Component.Spec

  specs CPU do

    def validate_spec(data),
      do: validate_has_keys(data, [:name, :price, :slot, :clock])

    spec :CPU_001 do

      %{
        name: "Threadisaster",
        price: 100,
        slot: :cpu,

        clock: 256
      }
    end
  end

  specs HDD do

    def validate_spec(data),
      do: validate_has_keys(data, [:name, :price, :slot, :size])

    spec :HDD_001 do

      %{
        name: "SemDisk",
        price: 150,
        slot: :sata,

        size: 1024,
        iops: 1000
      }
    end
  end
end
