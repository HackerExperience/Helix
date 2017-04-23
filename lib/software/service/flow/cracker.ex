defmodule Helix.Software.Service.Flow.Cracker do

  alias Helix.Process.Service.API.Process
  alias Software.Cracker.ProcessType

  import HELF.Flow

  def start_process(
    entity_id,
    gateway_id,
    network_id,
    target_ip,
    target_id,
    server_type)
  do
    # TODO: Check target firewall
    objective = %{cpu: 100_000}

    process_data = %ProcessType{
      entity_id: entity_id,
      network_id: network_id,
      target_server_ip: target_ip,
      target_server_id: target_id,
      server_type: server_type,
      software_version: 1
    }

    # TODO: start a connection for the process
    params = %{
      gateway_id: gateway_id,
      target_server_id: target_id,
      network_id: network_id,
      objective: objective,
      process_data: process_data,
      process_type: "cracker"
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
