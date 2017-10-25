# TODO: Delete this ? Yes please.

defmodule Helix.Test.Process.ProcessableExample do

  defstruct []

  defimpl Helix.Process.Model.Processable do
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
    def after_read_hook(data),
      do: data
  end
end

defmodule Helix.Test.Process.StaticProcessableExample do

  defstruct []

  defimpl Helix.Process.Model.Processable do
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
    def after_read_hook(data),
      do: data  end
end
