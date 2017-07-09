defmodule Helix.Process.Event.Cracker do
  @moduledoc false

  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Repo
  alias Software.Cracker.ProcessType, as: Cracker
  alias Helix.Software.Model.SoftwareType.Firewall.FirewallStartedEvent
  alias Helix.Software.Model.SoftwareType.Firewall.FirewallStoppedEvent

  def firewall_started(event = %FirewallStartedEvent{}) do
    # ME COOKIE MONSTER
    crackers =
      event.gateway_id
      |> ProcessQuery.get_processes_of_type_targeting_server("cracker")
      |> Enum.filter(&(&1.process_data.firewall_version < event.version))
      |> Enum.map(fn process ->
        base_fw_version = process.process_data.firewall_version

        base_cost = Cracker.firewall_additional_wu(base_fw_version)
        new_cost = Cracker.firewall_additional_wu(event.version)
        cost_diff = new_cost - base_cost

        process_data = %{process.process_data| firewall_version: event.version}
        objective = %{process.objective| cpu: process.objective.cpu + cost_diff}
        objective = Map.from_struct(objective)
        params = %{process_data: process_data, objective: objective}

        Process.update_changeset(process, params)
      end)

    {:ok, gateways} = Repo.transaction fn ->
      Enum.reduce(crackers, MapSet.new(), fn cracker, acc ->
        Repo.update!(cracker)

        MapSet.put(acc, Ecto.Changeset.get_field(cracker, :gateway_id))
      end)
    end

    Enum.each(gateways, fn gateway ->
      ProcessAction.reset_processes_on_server(gateway)
    end)
  end

  def firewall_stopped(event = %FirewallStoppedEvent{}) do
    crackers =
      event.gateway_id
      |> ProcessQuery.get_processes_of_type_targeting_server("cracker")
      |> Enum.filter(&(&1.process_data.firewall_version == event.version))
      |> Enum.map(fn process ->
        firewall_cost = Cracker.firewall_additional_wu(event.version)

        process_data = %{process.process_data| firewall_version: 0}
        cpu_objective = process.objective.cpu - firewall_cost
        objective = %{process.objective| cpu: cpu_objective}
        objective = Map.from_struct(objective)
        params = %{process_data: process_data, objective: objective}

        Process.update_changeset(process, params)
      end)

    {:ok, gateways} = Repo.transaction fn ->
      Enum.reduce(crackers, MapSet.new(), fn cracker, acc ->
        Repo.update!(cracker)

        MapSet.put(acc, Ecto.Changeset.get_field(cracker, :gateway_id))
      end)
    end

    Enum.each(gateways, fn gateway ->
      ProcessAction.reset_processes_on_server(gateway)
    end)
  end
end
