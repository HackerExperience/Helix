defmodule Helix.Server.Model.Server.PasswordAcquiredEvent do

  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server

  @type t :: %__MODULE__{
    entity_id: Entity.id,
    network_id: Network.id,
    server_id: Server.id,
    server_ip: IPv4.t,
    password: Server.password
  }

  @enforce_keys ~w/
    entity_id
    network_id
    server_id
    server_ip
    password
  /a
  defstruct ~w/
    entity_id
    network_id
    server_id
    server_ip
    password
  /a

  defimpl Helix.Event.Notificable do
    @moduledoc """
    The ServerPasswordAcquiredEvent is sent to the user after a Bruteforce
    attack has been completed, and the attacker discovered the target's server
    root password.

    It is always sent to the Account channel, so we don't need to filter data to
    unwanted listeners, like is the case for Server-level events.
    """

    @event "server_password_acquired"

    def generate_payload(event, _socket) do
      data = %{
        network_id: to_string(event.network_id),
        server_ip: event.server_ip,
        password: event.password
      }

      return = %{
        data: data,
        event: @event
      }

      {:ok, return}
    end

    def whom_to_notify(event),
      do: %{account: event.entity_id}
  end
end
