defmodule Helix.Test.Process.Macros do

  defmacro assert_objective(objective, resources) do
    quote do
      resources =
        if is_tuple(unquote(resources)) do
          [unquote(resources)]
        else
          unquote(resources)
        end

      acc_objective =
        Enum.reduce(resources, %{}, fn {resource, usage}, acc ->
          assert Map.get(unquote(objective), resource) == usage

          Map.put(acc, resource, usage)
        end)

      assert acc_objective == unquote(objective)
    end
  end
end
