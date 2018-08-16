defmodule Helix.Log.Event.Recover do

  import Helix.Event

  event Processed do
    @moduledoc """
    `LogRecoverProcessedEvent` is fired when the underlying LogRecoverProcess
    has achieved its objective and finished executing, thus popping the last
    revision from the Log.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Process.Model.Process
    alias Helix.Server.Model.Server
    alias Helix.Log.Model.Log
    alias Helix.Log.Process.Recover, as: LogRecoverProcess

    @type t ::
      %__MODULE__{
        method: LogRecoverProcess.method,
        server_id: Server.id,
        entity_id: Entity.id,
        target_log_id: Log.id | nil,
        recover_version: pos_integer
      }

      event_struct [
        :method,
        :server_id,
        :entity_id,
        :target_log_id,
        :recover_version
      ]

    @spec new(Process.t, LogRecoverProcess.t) ::
      t
    def new(process = %Process{}, data = %LogRecoverProcess{}) do
      %__MODULE__{
        method: get_method(process),
        server_id: process.target_id,
        entity_id: process.source_entity_id,
        target_log_id: process.tgt_log_id,
        recover_version: data.recover_version
      }

      # Later on, after we pop out the revision from the stack, we'll send a
      # SIGRETARGET signal to the process, so it can keep working on another log
      |> put_process(process)
    end

    defp get_method(%Process{type: :log_recover_global}),
      do: :global
    defp get_method(%Process{type: :log_recover_custom}),
      do: :custom
  end
end
