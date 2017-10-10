defmodule Helix.Software.Event.Cracker.Overflow do

  import Helix.Event

  event Processed do
    @moduledoc """
    OverflowProcessedEvent is fired when a OverflowProcess has completed its
    execution.
    """

    alias Helix.Network.Model.Connection
    alias Helix.Process.Model.Process
    alias Helix.Server.Model.Server
    alias Helix.Software.Model.Software.Cracker.Overflow, as: OverflowProcess

    @type t :: %__MODULE__{
      gateway_id: Server.id,
      target_process_id: Process.id | nil,
      target_connection_id: Connection.id | nil
    }

    event_struct [:gateway_id, :target_process_id, :target_connection_id]

    @spec new(Process.t, OverflowProcess.t) ::
      t
    def new(process = %Process{}, data = %OverflowProcess{}) do
      %__MODULE__{
        gateway_id: process.gateway_id,
        target_process_id: data.target_process_id,
        target_connection_id: data.target_connection_id
      }
    end
  end
end
