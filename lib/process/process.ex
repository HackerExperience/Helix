defmodule Helix.Process do

  @doc """
  Top-level macro for processes.
  """
  defmacro process(name, do: block) do
    quote do

      defmodule unquote(name) do

        # Imports all sub-modules that, together, will define the Process.
        import Helix.Process.Executable
        import Helix.Process.Resourceable
        import Helix.Process.Processable
        import Helix.Process.Viewable

        # Static types
        @type resource_usage :: Helix.Process.Resourceable.resource_usage

        # Custom types
        @type executable_error :: __MODULE__.Executable.executable_error

        @process_type nil

        unquote(block)

        @doc """
        Entry point for execution of the process.
        """
        defdelegate execute(gateway, target, params, meta),
          to: __MODULE__.Executable

        @doc """
        Returns the process type.
        """
        def get_process_type,
          do: @process_type
      end

    end
  end

  @doc """
  `get_resources` will pass the given params to `Process.Resourceable`, which
  will use its own flow to specify the required objectives the process should
  need for each hardware resource, as well as static and dynamic resource
  allocation usage.
  """
  defmacro get_resources(params) do
    quote bind_quoted: [params: params] do
      factors = __MODULE__.Resourceable.get_factors(params)

      objective = __MODULE__.Resourceable.calculate(params, factors)
      static = __MODULE__.Resourceable.static(params, factors)
      l_dynamic = __MODULE__.Resourceable.l_dynamic(params, factors)
      r_dynamic = __MODULE__.Resourceable.r_dynamic(params, factors)

      %{
        objective: objective,
        static: static,
        l_dynamic: l_dynamic,
        r_dynamic: r_dynamic
      }
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
