defmodule Helix.Server.Event.Server do

  import Helix.Event

  event Joined do
    @moduledoc """
    The `ServerJoinedEvent` is fired after a server is joined. It may be either
    a local or remote join.

    The `entity_id` in the event represents the Entity that performed the action
    (not necessarily the entity that owns the server).
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Server.Model.Server

    event_struct [:server_id, :entity_id, :join_type]

    @type t ::
      %__MODULE__{
        server_id: Server.id,
        entity_id: Entity.id,
        join_type: join_type
      }

    @type join_type ::
      :local
      | :remote

    @spec new(Server.t, Entity.t, join_type) ::
      t
    def new(server = %Server{}, entity = %Entity{}, type) do
      %__MODULE__{
        server_id: server.server_id,
        entity_id: entity.entity_id,
        join_type: type
      }
    end

    loggable do

      @doc """
        localhost logged in
      """
      log(event = %__MODULE__{join_type: :local}) do
        log_map %{
          event: event,
          server_id: event.server_id,
          entity_id: event.entity_id,
          type: :local_login,
          data: %{}
        }
      end

      # Does nothing on `remote` join, since that log is managed by the tunnel
      # being created during the join operation.
      log(%_{join_type: :remote}) do
        empty_log()
      end
    end
  end
end
