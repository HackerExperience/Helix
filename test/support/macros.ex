defmodule Helix.Test.Macros do

  defmacro assert_map(a, b, skip: skip) do
    skip = is_list(skip) && skip || [skip]
    quote bind_quoted: binding() do
      assert Map.drop(a, skip) == Map.drop(b, skip)
    end
  end
end
