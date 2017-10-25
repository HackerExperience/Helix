defmodule Helix.Process.Viewable do
  @moduledoc """
  Process.Viewable is called when we want to render the process, usually as part
  of a response's payload.

  This is only an interface for `Helix.Process.Public.View.ProcessViewable`,
  meant to facilitate the end-user's (programmer's) interface. If you want to
  understand what will be rendered, and how the rendering works, check that out.
  """

  @doc """
  Macro for implementation of the ProcessViewable protocol.

  It removes most of the boiler plate, making the process having to define only
  the custom `render_data` function.

  The boilerplate below, which uses `default_process_render`, is suitable for
  most processes. If one processes needs to have a custom behaviour, it should
  implement the ProcessViewable protocol directly, without using this macro.
  """
  defmacro process_viewable(do: block) do
    quote do

      defimpl Helix.Process.Public.View.ProcessViewable do
        @moduledoc false

        alias Helix.Process.Public.View.Process.Helper, as: ProcessViewHelper

        @doc false
        def get_scope(data, process, server, entity) do
          ProcessViewHelper.get_default_scope(data, process, server, entity)
        end

        @doc false
        def render(data, process, scope) do
          base = render_process(process, scope)
          complement = render_data(data, scope)

          {base, complement}
        end

        @doc false
        defp render_process(process, scope) do
          ProcessViewHelper.default_process_render(process, scope)
        end

        unquote(block)
      end

    end
  end

  @doc """
  Macro for implementing the `render_data/2` function required by the
  `process_viewable` macro.
  """
  defmacro render_data(data, scope, do: block) do
    quote do

      defp render_data(unquote(data), unquote(scope)) do
        unquote(block)
      end

    end
  end

  @doc """
  Shorthand for when the process has no meaningful metadata to be rendered.
  """
  defmacro render_empty_data do
    quote do

      @spec render_data(process :: struct, :full | :partial) ::
        data
      defp render_data(_, _) do
        %{}
      end

    end
  end
end
