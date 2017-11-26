defmodule Helix.Server.Component.Flow do
  @moduledoc """
  The `Component.Flow` is the skeleton/implementation of the `Componentable`.
  """

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

      @type type :: :cpu | :hdd | :ram | :nic | :mobo

      unquote(components_functions())

    end
  end

  defp components_functions do
    quote do

      @spec get_resources(Component.t) ::
        Component.custom
      @doc """
      Redirects the `get_resources` calls to each underlying component. The
      result is the component's total resources, which is aggregate/accumulated
      by the caller in order to get the total resources within a motherboard.
      """
      def get_resources(component),
        do: dispatch(component.type, :new, [component])

      @spec update_custom(Component.t, changes :: map) ::
        Component.custom
      @doc """
      Updates the custom fields of a component.

      This function is naive, in the sense that it simply merges both maps.
      Nasty things may happen if you pass invalid stuff. Hopefully dialyzer will
      watch our back.
      """
      def update_custom(component, changes),
        do: Map.merge(component.custom, changes)

      @spec dispatch(Component.type, atom, [args :: term]) ::
        term
      @doc """
      Dispatches the call `fun([args])` to the underlying component `type`.
      """
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
      @doc """
      Returns a list of all component types declared at `Componentable`.
      """
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

  @doc """
  Declares a new component. See `Componentable` for usage example.
  """
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

  @doc """
  Helper to return the component module name. It's mostly a frescura to have
  `MOBO` as a title (`Mobo`) and the other components in caps (`CPU`, `HDD`...)
  """
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
