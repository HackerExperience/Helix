defmodule Helix.Process.Service.Event.Cracker do
  @moduledoc false

  alias Software.Cracker.ProcessType, as: Cracker
  alias Helix.Software.Model.SoftwareType.Firewall.FirewallStarted
  alias Helix.Process.Model.Process
  alias Helix.Process.Service.API.Process, as: ProcessAPI
  alias Helix.Process.Repo

  def firewall_started(event = %FirewallStarted{}) do
    # ME COOKIE MONSTER
    crackers =
      event.gateway_id
      |> ProcessAPI.get_processes_of_type_targeting_server("cracker")
      |> Enum.map(&increase_wu_on_firewall_diff(&1, event.version))
      |> Enum.filter(&match?(%Ecto.Changeset{}, &1))

    {:ok, gateways} = Repo.transaction fn ->
      Enum.reduce(crackers, MapSet.new(), fn cracker, acc ->
        Repo.update!(cracker)

        MapSet.put(acc, Ecto.Changeset.get_field(cracker, :gateway_id))
      end)
    end

    Enum.each(gateways, fn gateway ->
      ProcessAPI.reset_processes_on_server(gateway)
    end)
  end

  defp increase_wu_on_firewall_diff(process, version) do
    base_fw_version = process.process_data.firewall_version
    if version > base_fw_version do
      base_cost = Cracker.firewall_additional_wu(base_fw_version)
      new_cost = Cracker.firewall_additional_wu(version)
      cost_diff = new_cost - base_cost

      process_data = %{process.process_data| firewall_version: version}
      objective = %{process.objective| cpu: process.objective.cpu + cost_diff}
      objective = Map.from_struct(objective)
      params = %{process_data: process_data, objective: objective}

      Process.update_changeset(process, params)
    else
      process
    end
  end
end
