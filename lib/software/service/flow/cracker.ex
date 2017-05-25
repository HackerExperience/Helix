defmodule Helix.Software.Service.Flow.Cracker do

  alias Helix.Process.Service.API.Process
  alias Software.Cracker.ProcessType, as: Cracker

  import HELF.Flow

  # TODO: Realocate this to FileFlow as execute_file
  def start_process(
    entity_id,
    gateway_id,
    network_id,
    target_ip,
    target_id,
    server_type)
  do
    firewall_version =
      target_id
      |> Process.get_running_processes_of_type_on_server("firewall_passive")
      |> Enum.reduce(0, &(max(&1.process_data.version, &2)))

    firewall_difficulty_increase = Cracker.firewall_additional_wu(
      firewall_version)
    base_crack_difficulty = 100_000

    objective = %{cpu: base_crack_difficulty + firewall_difficulty_increase}

    process_data = %Cracker{
      entity_id: entity_id,
      network_id: network_id,
      target_server_ip: target_ip,
      target_server_id: target_id,
      server_type: server_type,
      software_version: 1,
      firewall_version: firewall_version
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
