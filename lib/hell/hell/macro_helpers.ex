defmodule HELL.MacroHelpers do

  @doc """
  Simply ignores the input

  This macro exists solely to allow the use of heredocs to document private
  functions

  ## Example
      docp \"\"\"
      Does something
      \"\"\"
      defp some_fun(),
        do: :something
  """
  defmacro docp(_) do
    :ok
  end
end