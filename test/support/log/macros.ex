defmodule Helix.Test.Log.Macros do

  alias HELL.Utils

  @doc """
  Helper to assert the expected log was returned.

  `fragment` is a mandatory parameter, it's an excerpt of the log that must
  exist on the log content.

  Opts:
  - contains: List of words/terms that should be present on the log message
  - rejects: List of words/terms that must not be present on the log message
  """
  defmacro assert_log(log, s_id, e_id, fragment, opts \\ quote(do: [])) do
    contains = Keyword.get(opts, :contains, []) |> Utils.ensure_list()
    reject = Keyword.get(opts, :reject, []) |> Utils.ensure_list()

    quote do

      assert unquote(log).server_id == unquote(s_id)
      assert unquote(log).entity_id == unquote(e_id)
      assert unquote(log).message =~ unquote(fragment)

      Enum.each(unquote(contains), fn term ->
        assert unquote(log).message =~ term
      end)
      Enum.each(unquote(reject), fn term ->
        refute unquote(log).message =~ term
      end)

    end
  end
end
