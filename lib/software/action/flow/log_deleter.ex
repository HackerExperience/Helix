defmodule Helix.Software.Action.Flow.LogDeleter do

  import HELF.Flow

  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Software.LogDeleter.ProcessType

  def start_process(gateway_id, network_id, log_id) do
    log = LogQuery.fetch(log_id)
    objective = %{cpu: 20_000}

    process_data = %ProcessType{
      target_log_id: log_id,
      software_version: 1
    }

    # TODO: start a connection for the process
    params = %{
      gateway_id: gateway_id,
      target_server_id: log.server_id,
      network_id: network_id,
      objective: objective,
      process_data: process_data,
      process_type: "log_deleter"
    }

    flowing do
      with \
        {:ok, process} <- ProcessAction.create(params)
      do
        # Yay!
        # TODO: what is the proper return ?
        {:ok, process}
      end
    end
  end
end
