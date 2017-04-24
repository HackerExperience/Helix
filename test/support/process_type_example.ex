# TODO: Delete this ?

defmodule Helix.Process.TestHelper.ProcessTypeExample do

  defstruct []

  defimpl Helix.Process.Model.Process.ProcessType do
    def dynamic_resources(_),
      do: [:cpu, :dlk, :ulk]
    def minimum(_),
      do: %{}
    def conclusion(_, process) do
      process =
        process
        |> Ecto.Changeset.change()
        |> Map.put(:action, :delete)

      {process, []}
    end
    def event(_, _, _),
      do: []
  end
end

defmodule Helix.Process.TestHelper.StaticProcessTypeExample do

  defstruct []

  defimpl Helix.Process.Model.Process.ProcessType do
    def dynamic_resources(_),
      do: []
    def minimum(_),
      do: %{}
    def conclusion(_, process) do
      process =
        process
        |> Ecto.Changeset.change()
        |> Map.put(:action, :delete)

      {process, []}
    end
    def event(_, _, _),
      do: []
  end
end
