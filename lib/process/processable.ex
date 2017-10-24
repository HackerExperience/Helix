# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule Helix.Process.Processable do
  @moduledoc """
  Process.Processable is the core definition of a process' behavior. Among other
  things, it specifies what should happen when a process completes, and what
  should happen if the process gets killed.

  Due to our event-driven architecture, reactions to process completion/abortion
  should be made on the form of events, so as much as possible a Processable
  callback should never perform a direct action, relying on events to perform
  side-effects.
  """

  import HELL.Macros

  alias Helix.Process.Model.Process

  @doc """
  Macro for implementation of the Processable protocol.
  """
  defmacro processable(do: block) do
    quote location: :keep do

      defimpl Helix.Process.Model.Processable do

        unquote(block)

        # Fallbacks

        on_kill(_data, _reason) do
          {:ok, []}
        end

        @doc false
        def after_read_hook(data),
          do: data

        # Required by current TOP API

        @doc false
        def state_change(_, process, _, _),
          do: {process, []}

        @doc false
        def conclusion(data, process),
          do: state_change(data, process, :running, :complete)

        # Utils

        docp """
        Makes available, within the scope of all public Processable methods, the
        variable `process`, which is of type `Process.t`. This is required since
        because, for legacy reasons, TOP feeds the Changeset as argument, making
        the handling of `process` a lot harder.

        Well, this function -- and the way it's called from this module's macros
        -- ensures that a Processable method always deal with `Process.t`. as it
        should be.
        """
        defp unchange(process = %Process{}),
          do: process
        defp unchange(process = %Ecto.Changeset{}),
          do: Ecto.Changeset.apply_changes(process)

        docp """
        Flags the process for deletion.

        Current TOP needs that we return a process changeset with `action` set
        to `:delete`, so that's what we do here.
        """
        defp delete(process = %Process{}) do
          process
          |> Ecto.Changeset.change()
          |> delete()
        end
        defp delete(process = %Ecto.Changeset{}),
          do: %{process| action: :delete}

        # Result handlers

        docp """
        Called when `on_completion` finishes. Currently it supports:

        - `{:ok, events :: [Event.t]}`: Process is flagged for deletion and the
          corresponding events are emitted.
        """
        defp handle_completion_result({:ok, events}, process),
          do: {delete(process), events}

        docp """
        Called when `on_kill` finishes. Currently it supports:

        - `{:ok, events :: [Event.t]}`: Process is flagged for deletion and the
          corresponding events are emitted.
        """
        defp handle_kill_result({:ok, events}, process),
          do: {delete(process), events}
      end

    end
  end

  @doc """
  Defines what happens should the process get killed. Reason is also passed as
  argument.

  The result will be interpreted by `handle_kill_result/2`.
  """
  defmacro on_kill(data, reason \\ quote(do: _), do: block) do
    quote do

      def kill(unquote(data), process, unquote(reason)) do
        var!(process) = unchange(process)

        unquote(block)
        |> handle_kill_result(var!(process))
      end

    end
  end

  @doc """
  Defines what should happen when the process completes (finishes).

  The result will be interpreted by `handle_completion_result/2`.
  """
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
