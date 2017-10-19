defmodule Helix.Test.Event.Macros do

  @doc """
  It's common to assert two events are equal: the one before being emitted to
  the client, and the one after. In this case, the meta field `__meta__` is
  changed only on the later, but that's an implementation detail that our
  assertion does not care. Hence the purpose of this macro: assert two events
  are equal, or at least the part we care about.
  """
  defmacro assert_event(a, b) do
    quote do

      ev1 =
        unquote(a)
        |> Map.drop([:__meta__])

      ev2 =
        unquote(b)
        |> Map.drop([:__meta__])

      assert ev1 == ev2
    end
  end
end
