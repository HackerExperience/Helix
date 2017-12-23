defmodule Helix.Server.Event.Motherboard do

  import Helix.Event

  event Updated do
    @moduledoc """
    `MotherboardUpdatedEvent` is fired when the server motherboard has changed
    as a result of a player's action. Changes include removal of the mobo
    (detach) as well as (un)linking components.

    This data is Notificable, i.e. sent to the Client. The client receives the
    new motherboard data through HardwareIndex (same data sent during the
    bootstrap step).
    """

    alias Helix.Server.Model.Server
    alias Helix.Server.Public.Index.Hardware, as: HardwareIndex

    event_struct [:server, :index_cache]

    @type t :: %__MODULE__{
      server: Server.t,
      index_cache: HardwareIndex.index
    }

    @spec new(Server.t) ::
      t
    def new(server = %Server{}) do
      %__MODULE__{
        server: server,

        # `index_cache` is a cache of the new server hardware index (bootstrap)
        # We save it on the event struct so it is only generated once;
        # otherwise it would have to be recalculated to every player joined
        # on the server channel.
        # We save the full cache (`:local`) and, if the Notificable receiver is
        # a remote server, we nilify the `:motherboard` entry
        index_cache: HardwareIndex.index(server, :local)
      }
    end

    notify do

      @event :motherboard_updated

      @doc """
      The player (server channel with `local` access) receives the full hardware
      index, while any remote connection receives only remote data (like total
      hardware resources).
      """
      def generate_payload(event, %{assigns: %{meta: %{access: :local}}}) do
        data = HardwareIndex.render_index(event.index_cache)

        {:ok, data}
      end

      def generate_payload(event, %{assigns: %{meta: %{access: :remote}}}) do
        data =
          event.index_cache
          |> HardwareIndex.render_index()
          |> Map.replace(:motherboard, nil)

        {:ok, data}
      end

      def whom_to_notify(event),
        do: %{server: event.server.server_id}
    end
  end

  event UpdateFailed do
    @moduledoc """
    `MotherboardUpdateFailedEvent` is fired when the user attempted to update 
    her motherboard but it failed with `reason`. Client is notified (mostly
    because this is an asynchronous step).
    """

    alias Helix.Server.Model.Server

    event_struct [:server_id, :reason]

    @type t :: %__MODULE__{
      server_id: Server.id,
      reason: reason
    }

    @type reason :: :internal

    @spec new(Server.idt, reason) ::
      t
    def new(server = %Server{}, reason),
      do: new(server.server_id, reason)
    def new(server_id = %Server.ID{}, reason) do
      %__MODULE__{
        server_id: server_id,
        reason: reason
      }
    end

    notify do

      @event :motherboard_update_failed

      @doc """
      Only the player is notified (server channel with `local` access)
      """
      def generate_payload(event, %{assigns: %{meta: %{access: :local}}}) do
        data = %{reason: event.reason}

        {:ok, data}
      end
      def generate_payload(_, _),
        do: :noreply

      def whom_to_notify(event),
        do: %{server: event.server_id}
    end
  end
end
