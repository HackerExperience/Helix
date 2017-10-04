defmodule Helix.Henforcer do
  defmacro henforce(function, do: block) do
    quote do

      with {true, var!(relay)} <- unquote(function) do
        unquote(block)
      else
        not_found ->
          not_found
      end

    end
  end

  defmacro reply_ok(relay \\ quote(do: %{})) do
    quote do
      {true, unquote(relay)}
    end
  end

  defmacro reply_error(reason, relay \\ quote(do: %{})) do
    quote do
      {false, unquote(reason), unquote(relay)}
    end
  end

  defmacro relay(m1) do
    quote do
      unquote(m1)
    end
  end

  defmacro relay(m1, m2) do
    quote do
      Map.merge(unquote(m1), unquote(m2))
    end
  end
end
