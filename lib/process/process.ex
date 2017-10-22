defmodule Helix.Process do

  @doc """
  Top-level macro for processes.
  """
  defmacro process(name, do: block) do
    quote do

      defmodule unquote(name) do

        import Helix.Process.Executable
        import Helix.Process.Objective

        @type resource_usage :: Helix.Process.Objective.resource_usage

        @process_type nil

        unquote(block)

        defdelegate execute(gateway, target, params, meta),
          to: __MODULE__.Executable

        def get_process_type,
          do: @process_type |> to_string()
      end

    end
  end

  @doc """
  `set_objective` will pass the given params to `Process.Objective.calculate/2`,
  which will use its own flow to specify the required objectives the process
  should need for each hardware resource.
  """
  defmacro set_objective(params) do
    quote bind_quoted: [params: params] do
      factors = __MODULE__.Objective.get_factors(params)
      __MODULE__.Objective.calculate(params, factors)
    end
  end

  @doc """
  Generates the process struct, alongside any metadata (currently none).
  """
  defmacro process_struct(keys) do
    quote do

      @enforce_keys unquote(keys)
      defstruct unquote(keys)

    end
  end

  @doc """
  Macro for implementation of the ProcessType protocol.
  """
  defmacro process_type(do: block) do
    quote do

      defimpl Helix.Process.Model.Process.ProcessType do
        unquote(block)
      end

    end
  end

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

        def get_scope(data, process, server, entity) do
          ProcessViewHelper.get_default_scope(data, process, server, entity)
        end

        def render(data, process, scope) do
          base = render_process(process, scope)
          complement = render_data(data, scope)

          {base, complement}
        end

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

  defmacro render_empty_data do
    quote do

      @spec render_data(process :: struct, :full | :partial) ::
        data
      defp render_data(_, _) do
        %{}
      end

    end
  end

  @doc """
  Helper to make sure the given process is a valid Process.t, not a changeset.

  Non-hygienic macro, i.e. a new variable process is returned.
  """
  defmacro unchange(process) do
    quote do

      # The received process may be either a changeset or the model itself.....
      var!(process) =
        if unquote(process).__struct__ == Helix.Process.Model.Process do
          unquote(process)
        else
          Ecto.Changeset.apply_changes(unquote(process))
        end

    end
  end

  @doc """
  Helper to mark the process Changeset as deleted.

  Note both `delete/1` and `unchange/1` macros are a technical debt of a poor
  TOP interface. They should be removed once TOP is rewritten (#291).
  """
  defmacro delete(process) do
    quote do
      unquote(process)
      |> Ecto.Changeset.change()
      |> Map.put(:action, :delete)
    end
  end
end
