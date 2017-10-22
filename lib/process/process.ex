defmodule Helix.Process do

  @doc """
  Top-level macro for processes.
  """
  defmacro process(name, do: block) do
    quote do

      defmodule unquote(name) do

        import Helix.Process.Executable
        import Helix.Process.Objective
        import Helix.Process.Processable
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
end
