defmodule Helix.Server.Component.Flow do

  import HELL.Macros.Utils

  alias HELL.Utils
  alias Helix.Server.Model.Component

  defmacro __using__(_) do
    quote location: :keep do

      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :components, accumulate: true)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote location: :keep do

      unquote(components_functions())

    end
  end

  defp components_functions do
    quote do

      @spec get_resources(Component.t) ::
        Component.custom
      def get_resources(component),
        do: dispatch(component.type, :new, [component])

      @spec update_custom(Component.t, changes :: map) ::
        Component.custom
      def update_custom(component, changes) do
        component.custom
        |> Map.merge(changes)
      end

      @spec dispatch(Component.type, atom, [args :: term]) ::
        term
      def dispatch(type, fun, args) do
        component_module = get_module_name(type)

        module =
          Helix.Server.Model.Component
          |> Utils.concat_atom(".")
          |> Utils.concat_atom(component_module)

        apply(module, fun, args)
      end

      @spec get_types() ::
        [Component.type]
      def get_types,
        do: @components

      @spec get_module_name(Component.type) ::
        atom
      defp get_module_name(type) do
        type
        |> Atom.to_string()
        |> String.upcase()
        |> String.to_atom()
      end
    end
  end

  defmacro component(name, do: block) do
    comp_name = atomize_module_name(name)
    module_name = get_component_module(comp_name)

    quote do

      Module.put_attribute(
        unquote(__CALLER__.module),
        :components,
        unquote(comp_name)
      )

      defmodule unquote(module_name) do

        unquote(block)
      end

    end
  end

  def get_component_module(component) do
    case component do
      :mobo ->
        Helix.Server.Model.Component.Mobo

      elem ->
        Helix.Server.Model.Component
        |> Utils.concat_atom(".")
        |> Utils.concat_atom(Utils.upcase_atom(elem))
    end
  end
end
