defmodule HELL.MacroHelpers do

  @doc """
  On dev and prod environments, `hespawn` is the exact same thing as `spawn`.
  On test environments, `hespawn` will apply the given function synchronously.
  """
  defmacro hespawn(fun) do
    if Mix.env == :test do
      quote do
        apply(unquote(fun), [])
      end
    else
      quote do
        spawn(unquote(fun))
      end
    end
  end

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
  defmacro docp(_),
    do: :ok
end
