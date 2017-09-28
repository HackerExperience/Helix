defmodule Helix.Process.Model.Macros do

  defmacro unchange(process) do
    quote do
      Ecto.Changeset.apply_changes(unquote(process))
    end
  end

  defmacro delete(process) do
    quote do
      unquote(process)
      |> Ecto.Changeset.change()
      |> Map.put(:action, :delete)
    end
  end
end
