defmodule Helix.Software.Service.Flow.LogDeleter do

  alias Helix.Log.Service.API.Log
  alias Helix.Process.Service.API.Process
  alias Software.LogDeleter.ProcessType

  import HELF.Flow

  def start_process(gateway_id, network_id, log_id) do
    log = Log.fetch(log_id)
    objective = %{cpu: 20_000}

    process_data = %ProcessType{
      target_log_id: log_id
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
        {:ok, process} <- Process.create(params)
      do
        # Yay!
        # TODO: what is the proper return ?
        {:ok, process}
      end
    end
  end
end
