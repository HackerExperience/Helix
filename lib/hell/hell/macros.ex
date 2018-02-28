defmodule HELL.Macros do
  @moduledoc """
  Useful macros spread throughout Helix codebase.
  """

  alias HELL.Utils

  @doc """
  The `raisable/1` macro defines a raisable version of the given function
  `name/arity`. It expects the successful result to be of format {:ok, _}.
  """
  defmacro raisable({name, arity}) do
    fname =
      name
      |> Atom.to_string()
      |> Utils.concat("!")
      |> String.to_atom()

    params =
      1..arity
      |> Enum.map(fn i ->
        name = Utils.concat_atom(:arg, Integer.to_string(i))
        Macro.var(name, nil)
      end)

    quote do

      @doc false
      def unquote(fname)(unquote_splicing(params)) do
        {:ok, result} = unquote(name)(unquote_splicing(params))
        result
      end

    end
  end

  @doc """
  On dev and prod environments, `hespawn` is the exact same thing as `spawn`.
  On test environments, `hespawn` will call the given function synchronously.

  The flag `HELIX_FORCE_SYNC` may be used to force the synchronous behaviour,
  especially useful for specific `:dev` tests.
  """
  defmacro hespawn(fun) do
    force_sync? = System.get_env("HELIX_FORCE_SYNC") || false

    if Mix.env == :prod and force_sync?,
      do: raise "Can't set `HELIX_FORCE_SYNC` on prod"

    if Mix.env == :test or force_sync? do
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
