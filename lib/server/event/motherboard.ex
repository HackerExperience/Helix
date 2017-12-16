defmodule Helix.Server.Event.Motherboard do

  import Helix.Event

  event Updated do

    alias Helix.Server.Model.Server
    alias Helix.Server.Public.Index.Hardware, as: HardwareIndex

    event_struct [:server, :index_cache]

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

      def generate_payload(event, %{assigns: %{meta: %{access_type: :local}}}) do
        data = HardwareIndex.render_index(event.index_cache)

        {:ok, data}
      end

      def generate_payload(event, %{assigns: %{meta: %{access_type: :remote}}}) do
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

      def generate_payload(event, %{assigns: %{meta: %{access_type: :local}}}) do
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
