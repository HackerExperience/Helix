defmodule Helix.Process.Model.Process.ProcessCreatedEvent do

  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Process.Model.Process

  @type t :: %__MODULE__{
    process: Process.t,
    gateway_id: Server.id,
    target_id: Server.id,
    gateway_entity_id: Entity.id,
    target_entity_id: Entity.id,
    gateway_ip: IPv4.t,
    target_ip: IPv4.t
  }

  @enforce_keys ~w/
    process
    gateway_id
    target_id
    gateway_entity_id
    target_entity_id
    gateway_ip
    target_ip
  /a
  defstruct ~w/
    process
    gateway_id
    target_id
    gateway_entity_id
    target_entity_id
    gateway_ip
    target_ip
  /a

  defimpl Helix.Event.Notificable do

    @event "process_created"

    @doc """
    # ProcessCreatedEvent filtering

    Not all users have complete information about the process. Basically,

    1 - When an attacker `S` logs into a remote server `T`, `S` can fully see
    *all* processes *started by* the remote server.

    2 - Obviously, `S` can also see all processes started by herself and which
    are targeting `T`.

    3 - A third party `A`, unrelated to the process between `S` and `T`, can see
    the process, but without some information, namely, `S`'s IP. As consequence,
    `A` can't also see the connection ID.

      Note that if third party `A` is connected to `S`, she can see the full
    process because of 1. Hence, this rule (3) only applies to third-parties
    connecting to the attack target.
    """
    def generate_payload(event, socket) do
      gateway_id = socket.assigns.gateway.server_id
      destination_id = socket.assigns.destination.server_id

      cond do
        # attacker AT attack_source;
        # victim AT attack_target;
        # player AT action_server;
        gateway_id == destination_id ->
          payload(event, socket)

        # attacker AT attack_target
        event.gateway_id == gateway_id ->
          payload(event, socket)

        # victim AT attack_source
        event.target_id == gateway_id ->
          payload(event, socket)

        # third AT attack_source
        event.gateway_id == destination_id ->
          payload(event, socket)

        # third AT attack_target
        true ->
          payload(event, socket, [partial: true])
      end
    end

    defp payload(event, _socket, opts \\ []) do
      file_id = event.process.file_id && to_string(event.process.file_id)
      connection_id =
        event.process.connection_id && to_string(event.process.connection_id)

      data = %{
        process_id: to_string(event.process.process_id),
        type: to_string(event.process.process_type),
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

      return = %{
        data: data,
        event: @event
      }

      {:ok, return}
    end

    def whom_to_notify(event) do
      [event.gateway_id, event.target_id]
      |> Enum.uniq()
      |> Enum.map(&("server:" <> to_string(&1)))
    end
  end
end

defmodule Helix.Process.Model.Process.ProcessConclusionEvent do
  @moduledoc """
  This event is used solely to update the TOP display on the client.
  """

  alias Helix.Server.Model.Server

  @type t :: %__MODULE__{
    gateway_id: Server.id,
    target_id: Server.id
  }

  @enforce_keys [:gateway_id, :target_id]
  defstruct [:gateway_id, :target_id]

  defimpl Helix.Event.Notificable do

    @event "process_conclusion"

    def generate_payload(_event, _socket) do
      data = %{
      }

      return = %{
        data: data,
        event: @event
      }

      {:ok, return}
    end

    def whom_to_notify(event) do
      [event.gateway_id, event.target_id]
      |> Enum.uniq()
      |> Enum.map(&("server:" <> to_string(&1)))
    end
  end
end
