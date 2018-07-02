defmodule Helix.Core.Validator.Model do
  @moduledoc """
  This is a helper module to create a syntactic sugar for Helix models that
  implement verifications for the `Helix.Core.Validator`.
  """

  @doc """
  Pure syntactic sugar.
  """
  defmacro validator(do: block) do
    parent_module = __CALLER__.module
    module_name = Module.concat(parent_module, "Validator")

    quote do

      defmodule unquote(module_name) do
        alias unquote(parent_module)

        unquote(block)
      end

    end
  end
end
