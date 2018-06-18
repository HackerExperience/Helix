defmodule Helix.Process.Event.Process do

  import Helix.Event

  event Created do
    @moduledoc """
    `ProcessCreatedEvent` is fired when a process is created. This event has an
    initial optimistic behaviour, so it is fired in two different moments.

    First, it is fired from ProcessAction, right after the process is created
    and inserted on the database. On this stage, the Process is said to be
    optimistic (unconfirmed) because the server may not be able to allocate
    resources to this process.

    This same event may be fired again from the TOPHandler, in which case the
    allocation was successful and the process creation has been confirmed. We
    only publish to the Client if the process is confirmed as created.

    If creation fails, we emit the `ProcessCreateFailedEvent`.
    """

    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Process.Model.Process

    @type t :: %__MODULE__{
      process: Process.t,
      confirmed: boolean,
      gateway_id: Server.id,
      target_id: Server.id,
      gateway_ip: Network.ip,
      target_ip: Network.ip
    }

    event_struct [
      :process,
      :confirmed,
      :gateway_id,
      :target_id,
      :gateway_ip,
      :target_ip
    ]

    @spec new(Process.t, Network.ip, Network.ip, [confirmed: boolean]) ::
      t
    @doc """
    Creates the process struct when it is unconfirmed (we don't know yet whether
    the allocation will be successful).
    """
    def new(process = %Process{}, source_ip, target_ip, confirmed: confirmed) do
      %__MODULE__{
        process: process,
        confirmed: confirmed,
        gateway_id: process.gateway_id,
        target_id: process.target_id,
        gateway_ip: source_ip,
        target_ip: target_ip
      }
    end

    @spec new(t) ::
      t
    @doc """
    When recreating the process from a previous event, we are effectively saying
    that the process creation has been confirmed.
    """
    def new(event = %__MODULE__{confirmed: false}),
      do: %{event| confirmed: true}

    publish do

      alias Helix.Process.Public.View.Process, as: ProcessView

      @event :process_created

      @doc """
      # ProcessCreatedEvent filtering

      Not all users have complete information about the process. Basically,

      1 - When an attacker `S` logs into a remote server `T`, `S` can fully see
      *all* processes *started by* the remote server.

      2 - Obviously, `S` can also see all processes started by herself and which
      are targeting `T`.

      3 - A third party `A`, unrelated to the process between `S` and `T`, can
      see the process, but without some information, namely, `S`'s IP. As
      consequence, `A` can't also see the connection ID.

      Note that if third party `A` is connected to `S`, she can see the full
      process because of 1. Hence, this rule (3) only applies to third-parties
      connecting to the attack target.

      All this logic is handled by `ProcessView` and, under the hood,
      `ProcessViewable`.
      """
      def generate_payload(event = %_{confirmed: true}, socket) do
        server_id = socket.assigns.destination.server_id
        entity_id = socket.assigns.gateway.entity_id

        data =
          ProcessView.render(
            event.process.data, event.process, server_id, entity_id
          )

        {:ok, data}
      end

      # Internal event used for optimistic (asynchronous) processing
      def generate_payload(%_{confirmed: false}, _),
        do: :noreply

      @doc """
      Both gateway and destination receive the publication. If they are the
      same, only one publication will be sent out.
      """
      def whom_to_publish(event),
        do: %{server: [event.gateway_id, event.target_id]}
    end
  end

  event Completed do
    @moduledoc """
    `ProcessCompletedEvent` is fired after a process has met its objective, and
    the corresponding `Processable.conclusion/2` callback was executed.

    More specifically, `ProcessCompletedEvent` is emitted right after the
    process is deleted - because it is now completed.

    It is used to publish to the Client that a process has finished. Note that
    it *only* means the process has completed, it has absolutely no information
    whether the process succeeded or not. This information - the actual process
    "result" - will be sent afterwards, as it is being computed in parallel.
    """

    alias Helix.Process.Model.Process

    event_struct [:process]

    @type t :: %__MODULE__{
      process: Process.t
    }

    @spec new(Process.t) ::
      t
    def new(process = %Process{}) do
      %__MODULE__{
        process: process
      }
    end

    publish do

      @event :process_completed

      def generate_payload(event, _socket) do
        data = %{
          process_id: event.process.process_id |> to_string()
        }

        {:ok, data}
      end

      def whom_to_publish(event),
        do: %{server: [event.process.gateway_id, event.process.target_id]}
    end
  end

  event Signaled do
    @moduledoc """
    `ProcessSignaledEvent` is fired when the process receives a signal. A signal
    is an instruction to the process, which shall be handled by `Processable`.
    If the process does not implement the corresponding handler, then the
    signal's default action will be performed.

    This is probably the single most important event of the TOP - and the game -
    since all changes in a process, including its completion, are handled by
    signals being delivered to it.

    Granted, `ProcessSignaledEvent` is emitted *after* the signal was delivered
    and handled by the corresponding Processable implementation, but the actual
    change to the process (defined at `action`) will be performed once this
    event is emitted.
    """

    alias Helix.Process.Model.Process

    event_struct [:process, :action, :signal, :params]

    def new(signal, process = %Process{}, action, params) do
      %__MODULE__{
        signal: signal,
        process: process,
        action: action,
        params: params
      }
    end
  end

  event Killed do
    @moduledoc """
    `ProcessKilledEvent` is fired when a process has been killed. The process
    no longer exists on the database on the moment this event was created.
    """

    alias Helix.Process.Model.Process

    event_struct [:process, :reason]

    @type t ::
      %__MODULE__{
        process: Process.t,
        reason: Process.kill_reason
      }

    @spec new(Process.t, Process.kill_reason) ::
      t
    def new(process = %Process{}, reason) do
      %__MODULE__{
        process: process,
        reason: reason
      }
    end

    publish do

      @event :process_killed

      @doc false
      def generate_payload(event, _socket) do
        data = %{
          process_id: event.process.process_id |> to_string(),
          reason: event.reason |> to_string()
        }

        {:ok, data}
      end

      @doc false
      def whom_to_publish(event),
        do: %{server: [event.process.gateway_id, event.process.target_id]}
    end
  end
end
