defmodule Helix.Process do

  alias Helix.Process.Model.Process

  @doc """
  Top-level macro for processes.
  """
  defmacro process(name, do: block) do
    quote do

      defmodule unquote(name) do

        import Helix.Process.Executable
        import Helix.Process.Objective
        import Helix.Process.Viewable

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
    quote location: :keep do

      defimpl Helix.Process.Model.Process.ProcessType do

        unquote(block)

        # Fallbacks

        on_kill(_data, _reason) do
          {:ok, []}
        end

        def after_read_hook(data),
          do: data

        # Required by current TOP API

        def state_change(_, process, _, _),
          do: {process, []}

        def conclusion(data, process),
          do: state_change(data, process, :running, :complete)

        # Utils

        defp unchange_f(process = %Process{}),
          do: process
        defp unchange_f(process = %Ecto.Changeset{}),
          do: Ecto.Changeset.apply_changes(process)

        defp delete_f(process = %Process{}) do
          process
          |> Ecto.Changeset.change()
          |> delete_f()
        end
        defp delete_f(process = %Ecto.Changeset{}),
          do: %{process| action: :delete}

        # Result handlers

        defp handle_completion_result({:ok, events}, process),
          do: {delete_f(process), events}

        defp handle_kill_result({:ok, events}, process),
          do: {delete_f(process), events}
      end

    end
  end

  defmacro on_kill(data, reason \\ quote(do: _), do: block) do
    quote do

      def kill(unquote(data), process, unquote(reason)) do
        var!(process) = unchange_f(process)

        unquote(block)
        |> handle_kill_result(var!(process))
      end

    end
  end

  defmacro on_completion(data, do: block) do
    quote do

      def state_change(unquote(data), process, _, :complete) do
        var!(process) = unchange_f(process)

        unquote(block)
        |> handle_completion_result(var!(process))
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
