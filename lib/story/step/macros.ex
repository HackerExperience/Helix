defmodule Helix.Story.Step.Macros do
  defmacro step(name, do: block) do
    quote do
      defmodule unquote(name) do

        require Helix.Story.Step

        Helix.Story.Step.register()

        defimpl Helix.Story.Steppable do
          unquote(block)
        end
      end
    end
  end

  defmacro next_step(step_module) do
    quote do
      unless Code.ensure_compiled?(unquote(step_module)) do
        raise "The step #{inspect unquote(step_module)} does not exist"
      end

      def next_step(_step) do
        Helix.Story.Step.get_step_name(unquote(step_module))
      end
    end
  end
end
