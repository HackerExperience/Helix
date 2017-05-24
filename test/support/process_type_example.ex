# TODO: Delete this ?

defmodule Helix.Process.TestHelper.ProcessTypeExample do

  defstruct []

  defimpl Helix.Process.Model.Process.ProcessType do
    def dynamic_resources(_),
      do: [:cpu, :dlk, :ulk]
    def minimum(_),
      do: %{}
    def kill(_, process, _),
      do: {%{Ecto.Changeset.change(process)| action: :delete}, []}
    def state_change(_, process, _, :complete) do
      process =
        process
        |> Ecto.Changeset.change()
        |> Map.put(:action, :delete)

      {process, []}
    end
    def state_change(_, process, _, _),
      do: {process, []}
    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)
  end
end

defmodule Helix.Process.TestHelper.StaticProcessTypeExample do

  defstruct []

  defimpl Helix.Process.Model.Process.ProcessType do
    def dynamic_resources(_),
      do: []
    def minimum(_),
      do: %{}
    def kill(_, process, _),
      do: {%{Ecto.Changeset.change(process)| action: :delete}, []}
    def state_change(_, process, _, :complete) do
      process =
        process
        |> Ecto.Changeset.change()
        |> Map.put(:action, :delete)

      {process, []}
    end
    def state_change(_, process, _, _),
      do: {process, []}
    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)
  end
end
