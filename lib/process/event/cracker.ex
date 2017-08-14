defmodule Helix.Process.Event.Cracker do
  @moduledoc false

  alias Ecto.Changeset
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.SoftwareType.Cracker
  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Repo

  alias Helix.Software.Model.SoftwareType.Firewall.FirewallStartedEvent
  alias Helix.Software.Model.SoftwareType.Firewall.FirewallStoppedEvent

  def firewall_started(event = %FirewallStartedEvent{}) do
    event.gateway_id
    |> ProcessQuery.get_processes_of_type_targeting_server("cracker")
    |> Enum.filter(&(&1.process_data.firewall_version < event.version))
    |> processes_changeset(event.version)
    |> update_on_database()
    |> notify_top()
  end

  def firewall_stopped(event = %FirewallStoppedEvent{}) do
    event.gateway_id
    |> ProcessQuery.get_processes_of_type_targeting_server("cracker")
    |> Enum.filter(&(&1.process_data.firewall_version == event.version))
    |> processes_changeset(event.version)
    |> update_on_database()
    |> notify_top()
  end

  @spec processes_changeset([Process.t], non_neg_integer) ::
    [Changeset.t]
  defp processes_changeset(processes, version) do
    Enum.map(processes, fn process ->
      {:ok, cracker} = Cracker.firewall_version(process.process_data, version)
      objective = Cracker.objective(cracker)

      params = %{process_data: cracker, objective: objective}

      Process.update_changeset(process, params)
    end)
  end

  @spec update_on_database([Changeset.t]) ::
    {:ok, MapSet.t(Server.id)}
  defp update_on_database(changesets) do
    Repo.transaction fn ->
      Enum.reduce(changesets, MapSet.new(), fn cracker, acc ->
        Repo.update!(cracker)

        gateway = Changeset.get_field(cracker, :gateway_id)

        MapSet.put(acc, gateway)
      end)
    end
  end

  @spec notify_top({:ok, MapSet.t(Server.id)}) ::
    :ok
  defp notify_top({:ok, gateways}),
    do: Enum.each(gateways, &ProcessAction.reset_processes_on_server/1)
end
