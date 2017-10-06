defmodule Helix.Process.Model.Macros do

  defmacro unchange(process) do
    quote do

      # The received process may be either a changeset or the model itself.....
      var!(process) =
        if unquote(process).__struct__ == Helix.Process.Model.Process do
          unquote(process)
        else
          Ecto.Changeset.apply_changes(unquote(process))
        end

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
