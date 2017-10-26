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

  defmacro assert_resource(res1, res2) do
    quote bind_quoted: binding() do
      if is_map(res1) do
        Enum.each(res1, fn {key, v1} ->

          v2 = is_map(res2) && Map.get(res2, key) || res2

          assert_in_delta v1, v2, 2
        end)
      else
        assert_in_delta res1, res2, 2
      end

      # res1 = is_map(res1) && res1.total || res1
      # res2 = is_map(res2) && res2.total || res2

    end
  end

  defmacro refute_resource(res1, res2) do
    quote bind_quoted: binding() do
      res1 = is_map(res1) && res1.total || res1
      res2 = is_map(res2) && res2.total || res2

      refute_in_delta res1, res2, 2
    end
  end
end
