defmodule Helix.Process.Event.Process do

  import Helix.Event

  event Created do

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

    # @spec new(Process.t, Network.ip, Network.ip, [optimistic: boolean]) ::
    #   t
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

    def new(event = %__MODULE__{confirmed: false}),
      do: %{event| confirmed: true}

    notify do

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
      """
      def generate_payload(event = %_{confirmed: true}, socket) do
        gateway_id = socket.assigns.gateway.server_id
        destination_id = socket.assigns.destination.server_id

        cond do
          # attacker AT attack_source;
          # victim AT attack_target;
          # player AT action_server;
          gateway_id == destination_id ->
            do_payload(event, socket)

          # attacker AT attack_target
          event.gateway_id == gateway_id ->
            do_payload(event, socket)

          # victim AT attack_source
          event.target_id == gateway_id ->
            do_payload(event, socket)

          # third AT attack_source
          event.gateway_id == destination_id ->
            do_payload(event, socket)

          # third AT attack_target
          true ->
            do_payload(event, socket, [partial: true])
        end
      end

      defp do_payload(event, _socket, opts \\ []) do
        file_id = event.process.file_id && to_string(event.process.file_id)
        connection_id =
          event.process.connection_id && to_string(event.process.connection_id)

        data = %{
          process_id: to_string(event.process.process_id),
          type: to_string(event.process.type),
          network_id: to_string(event.process.network_id),
          file_id: file_id,
          connection_id: connection_id,
          source_ip: event.gateway_ip,
          target_ip: event.target_ip
        }

        data =
          if opts[:partial] do
            data
            |> Map.drop([:connection_id])
            |> Map.drop([:source_ip])
          else
            data
          end

        {:ok, data}
      end

      # Internal event used for optimistic (asynchronous) processing
      def generate_payload(%_{confirmed: false}, _),
        do: :noreply

      @doc """
      Both gateway and destination are notified. If they are the same, obviously
      notifies only one.
      """
      def whom_to_notify(event),
        do: %{server: [event.gateway_id, event.target_id]}
    end
  end

  event Completed do
    @moduledoc """
    This event is used solely to update the TOP display on the client.
    """

    alias Helix.Event
    alias Helix.Server.Model.Server
    alias Helix.Process.Model.Process

    @type t :: %__MODULE__{
      gateway_id: Server.id,
      target_id: Server.id
    }

    event_struct [:gateway_id, :target_id]

    @spec new(Process.t) ::
      t
    def new(process = %Process{}) do
      %__MODULE__{
        gateway_id: process.gateway_id,
        target_id: process.target_id
      }
    end

    notify do

      @event :process_completed

      def generate_payload(event, _socket) do
        data = %{
          process_id: Event.get_process_id(event)
        }

        {:ok, data}
      end

      def whom_to_notify(event),
        do: %{server: [event.gateway_id, event.target_id]}
    end
  end
end
