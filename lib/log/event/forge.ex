defmodule Helix.Log.Event.Forge do

  import Helix.Event

  event Processed do
    @moduledoc """
    `LogForgeProcessedEvent` is fired when the underlying LogForgeProcess has
    achieved its objective and finished executing.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Process.Model.Process
    alias Helix.Server.Model.Server
    alias Helix.Log.Model.Log
    alias Helix.Log.Process.Forge, as: LogForgeProcess

    @type t ::
      %__MODULE__{
        action: LogForgeProcess.action,
        server_id: Server.id,
        entity_id: Entity.id,
        target_log_id: Log.id | nil,
        log_info: Log.info,
        forger_version: pos_integer
      }

      event_struct [
        :action,
        :server_id,
        :entity_id,
        :target_log_id,
        :log_info,
        :forger_version
      ]

    @spec new(Process.t, LogForgeProcess.t) ::
      t
    def new(process = %Process{}, data = %LogForgeProcess{}) do
      %__MODULE__{
        action: get_action(process),
        server_id: process.target_id,
        entity_id: process.source_entity_id,
        target_log_id: process.tgt_log_id,
        log_info: {data.log_type, data.log_data},
        forger_version: data.forger_version
      }
    end

    defp get_action(%Process{type: :log_forge_create}),
      do: :create
    defp get_action(%Process{type: :log_forge_edit}),
      do: :edit
  end
end
