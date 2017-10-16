defmodule Helix.Test.Henforcer.Macros do

  @doc """
  Basically, this macro ensures that the returned relay has the given keys and
  only them. It did not return any extra keys. Useful to test that the relay
  accumulation worked as expected.
  """
  defmacro assert_relay(relay, keys) do
    quote do
      acc_relay =
        Enum.reduce(unquote(keys), %{}, fn key, acc ->
          # Ensures the key exists on the relay
          assert Map.has_key?(unquote(relay), key)

          # Accumulate all keys, which will be used later to ensure the relay
          # has the given keys and only them, any extra key will raise an error
          Map.put(acc, key, unquote(relay)[key])
        end)

      assert unquote(relay) == acc_relay
    end
  end
end
