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
      end

    end
  end

  @doc """
  Defines what happens should the process get killed. Reason is also passed as
  argument.
  """
  defmacro on_kill(process, data, reason \\ quote(do: _), do: block) do
    quote do

      def kill(unquote(data), unquote(process), unquote(reason)) do
        unquote(block)
      end

    end
  end

  @doc """
  Defines what should happen when the process completes (finishes).
  """
  defmacro on_completion(process, data, do: block) do
    quote do

      def complete(unquote(data), unquote(process)) do
        unquote(block)
      end

    end
  end
end
