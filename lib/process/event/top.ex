defmodule Helix.Process.Event.TOP do

  import Helix.Event

  event BringMeToLife do
    @moduledoc """
    The `TOPBringMeToLifeEvent` is fired when the process supposedly reached its
    objective.

    It is created and maintained by TOPAction's `handle_next`, which will get
    the Scheduler's forecast result and emit this event after X seconds, where
    X seconds is the time left for completion of the next process.
    """

    alias Helix.Process.Model.Process

    @type t ::
      %__MODULE__{
        process_id: Process.id
      }

    event_struct [:process_id]

    @spec new(Process.t) ::
      t
    def new(process = %Process{}) do
      # We do not store the process struct itself because it may be used several
      # seconds later. By storing `process_id` directly, we force any subscriber
      # to always fetch the most recent process information.
      %__MODULE__{
        process_id: process.process_id
      }
    end
  end

  event Recalcado do
    @moduledoc """
    The `TOPRecalcadoEvent` is fired every time a TOP recalculation takes place
    in a server.

    It's quite important to publish to the Client that the TOP has changed.
    """

    alias Helix.Server.Model.Server

    @type t ::
      %__MODULE__{
        server_id: Server.id
      }

    event_struct [:server_id]

    @spec new(Server.id) ::
      t
    def new(server_id = %Server.ID{}) do
      %__MODULE__{
        server_id: server_id
      }
    end

    publish do
      @moduledoc """
      Publishes to the Client(s) that the TOP has changed. Instead of sending a
      diff of what has changed, we send the whole TOP, as the Client would
      receive if it were logging in for the first time.
      """

      alias Helix.Process.Public.Index, as: ProcessIndex

      @event :top_recalcado

      def generate_payload(event, socket) do
        data = ProcessIndex.index(event.server_id, socket.assigns.entity_id)

        {:ok, data}
      end

      def whom_to_publish(event),
        do: %{server: event.server_id}
    end
  end
end
