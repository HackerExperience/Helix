defmodule Helix.Server.Component.Flow do

  import HELL.Macros.Utils

  alias HELL.Utils

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

      def get_resources(component),
        do: dispatch(component.type, :new, [component])

      def dispatch(type, fun, args) do
        component_module = get_module_name(type)

        module =
          __MODULE__
          |> Utils.concat_atom(".")
          |> Utils.concat_atom(component_module)

        apply(module, fun, args)
      end

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

    quote do

      Module.put_attribute(
        unquote(__CALLER__.module),
        :components,
        unquote(comp_name)
      )

      defmodule unquote(name) do

        unquote(block)
      end

    end
  end

  defmacro custom(do: block) do
    quote do

      module_name =
        __MODULE__
        |> Module.split()
        |> Enum.take(-1)
        |> List.first()
        |> String.downcase()
        |> String.to_atom()
        |> case do
             :mobo ->
               Helix.Server.Model.Component.Mobo

             elem ->
               Utils.concat_atom(
                 Helix.Server.Model.Component, Utils.upcase_atom(elem)
               )
           end

      defmodule module_name do

        unquote(block)
      end
    end
  end

  # Default behaviour is to get the given resource field directly. For custom
  # implementation, use `resource/2`
  defmacro resource(name) when is_atom(name) do
    quote do

      def unquote(:"get_#{name}")(component) do
        Map.fetch!(component, unquote(name))
      end

    end
  end
end
