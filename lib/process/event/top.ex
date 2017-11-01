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
end
