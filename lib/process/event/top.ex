defmodule Helix.Process.Event.TOP do

  import Helix.Event

  event BringMeToLife do

    alias Helix.Process.Model.Process

    @type t :: term

    event_struct [:process_id]

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

    alias Helix.Server.Model.Server

    @type t :: term

    event_struct [:server_id]

    def new(server_id = %Server.ID{}) do
      %__MODULE__{
        server_id: server_id
      }
    end

    notify do
      @moduledoc """
      Notifies a client that the TOP has changed. Instead of sending a diff of
      what has changed, we send the whole TOP, as the Client would receive if it
      were logging in for the first time.
      """

      alias Helix.Process.Public.Index, as: ProcessIndex

      @event :top_recalcado

      def generate_payload(event, socket) do
        data = ProcessIndex.index(event.server_id, socket.assigns.entity_id)

        {:ok, data}
      end

      def whom_to_notify(event),
        do: %{server: event.server_id}
    end
  end
end
