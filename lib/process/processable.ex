defmodule Helix.Process.Processable do

  alias Helix.Process.Model.Process

  @doc """
  Macro for implementation of the ProcessType protocol.
  """
  defmacro process_type(do: block) do
    quote location: :keep do

      defimpl Helix.Process.Model.Process.ProcessType do

        unquote(block)

        # Fallbacks

        on_kill(_data, _reason) do
          {:ok, []}
        end

        def after_read_hook(data),
          do: data

        # Required by current TOP API

        def state_change(_, process, _, _),
          do: {process, []}

        def conclusion(data, process),
          do: state_change(data, process, :running, :complete)

        # Utils

        defp unchange(process = %Process{}),
          do: process
        defp unchange(process = %Ecto.Changeset{}),
          do: Ecto.Changeset.apply_changes(process)

        defp delete(process = %Process{}) do
          process
          |> Ecto.Changeset.change()
          |> delete()
        end
        defp delete(process = %Ecto.Changeset{}),
          do: %{process| action: :delete}

        # Result handlers

        defp handle_completion_result({:ok, events}, process),
          do: {delete(process), events}

        defp handle_kill_result({:ok, events}, process),
          do: {delete(process), events}
      end

    end
  end

  defmacro on_kill(data, reason \\ quote(do: _), do: block) do
    quote do

      def kill(unquote(data), process, unquote(reason)) do
        var!(process) = unchange(process)

        unquote(block)
        |> handle_kill_result(var!(process))
      end

    end
  end

  defmacro on_completion(data, do: block) do
    quote do

      def state_change(unquote(data), process, _, :complete) do
        var!(process) = unchange(process)

        unquote(block)
        |> handle_completion_result(var!(process))
      end

    end
  end
end
