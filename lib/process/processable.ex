# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule Helix.Process.Processable do
  @moduledoc """
  Process.Processable is the core definition of a process' behavior. Among other
  things, it specifies what should happen when a process completes, and what
  should happen if the process gets killed.

  It is the complete specification of how a process should react to signals.

  Due to our event-driven architecture, reactions to process completion/abortion
  should be made on the form of events, so as much as possible a Processable
  callback should never perform a direct action, always relying on events to
  perform side-effects.
  """

  import HELL.Macros

  alias Helix.Event

  @doc """
  Macro for implementation of the Processable protocol.
  """
  defmacro processable(do: block) do
    quote location: :keep do

      defimpl Helix.Process.Model.Processable do

        unquote(block)

        # Fallbacks

        on_kill(_process, _data, _reason) do
          {:delete, []}
        end

        on_retarget(_process, _data) do
          {:noop, []}
        end

        on_source_connection_closed(_process, _data, _connection) do
          {{:SIGKILL, :src_connection_closed}, []}
        end

        on_target_connection_closed(_process, _data, _connection) do
          {{:SIGKILL, :tgt_connection_closed}, []}
        end

        @doc false
        def after_read_hook(data),
          do: data

        # Utils

        docp """
        Save the `process_id` on the events that will be emitted. This may be
        used later by TOPHandler to make sure that some signals are filtered,
        avoiding that a process receives the signal of a side-effect performed
        by the process itself.
        """
        defp add_fingerprint({action, events}, %{process_id: process_id}) do
          events = Enum.map(events, &(Event.set_process_id(&1, process_id)))

          {action, events}
        end
      end

    end
  end

  @doc """
  Called when the process receives a SIGTERM.

  Defines what should happen when the process completes (finishes).

  Does not have a default behaviour. *Must* be implemented by the process.
  """
  defmacro on_completion(process, data, do: block) do
    quote do

      def complete(unquote(data), p = unquote(process)) do
        unquote(block)
        |> add_fingerprint(p)
      end

    end
  end

  @doc """
  Called when the process receives a SIGKILL.

  Defines what happens should the process get killed. Reason is also passed as
  argument.

  Default behaviour is to delete the process.
  """
  defmacro on_kill(process, data, reason \\ quote(do: _), do: block) do
    quote do

      def kill(unquote(data), p = unquote(process), unquote(reason)) do
        unquote(block)
        |> add_fingerprint(p)
      end

    end
  end

  @doc """
  Called when the process receives a SIGRETARGET.

  Defines what should happen when the process is asked to look for a new target.

  Default behaviour is to ignore the signal.
  """
  defmacro on_retarget(process, data, do: block) do
    quote do

      def retarget(unquote(data), p = unquote(process)) do
        unquote(block)
        |> add_fingerprint(p)
      end

    end
  end

  @doc """
  Called when the process receives a SIGSRCCONND.

  Defines what should happen when the process' underlying connection is closed.

  Default behaviour is to send a SIGKILL to itself.
  """
  defmacro on_source_connection_closed(process, data, connection, do: block) do
    quote do

      def source_connection_closed(
        unquote(data), p = unquote(process), unquote(connection)
      ) do
        unquote(block)
        |> add_fingerprint(p)
      end

    end
  end

  @doc """
  Called when the process receives a SIGTGTCONND.

  Defines what should happen when the process' target connection is closed.

  Default behaviour is to send a SIGKILL to itself.
  """
  defmacro on_target_connection_closed(process, data, connection, do: block) do
    quote do

      def target_connection_closed(
        unquote(data), p = unquote(process), unquote(connection)
      ) do
        unquote(block)
        |> add_fingerprint(p)
      end

    end
  end
end
