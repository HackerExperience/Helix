defmodule Helix.Process.Event.Cracker do
  @moduledoc false

  alias Ecto.Changeset
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.Software.Cracker.Bruteforce, as: CrackerBruteforce
  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Repo

  alias Helix.Software.Model.SoftwareType.Firewall.FirewallStartedEvent
  alias Helix.Software.Model.SoftwareType.Firewall.FirewallStoppedEvent

  def firewall_started(event = %FirewallStartedEvent{}) do
    event.gateway_id
    |> ProcessQuery.get_processes_of_type_targeting_server("cracker")
    |> processes_changeset(event.version)
    |> repo_update_all()
    |> notify_top()
  end

  def firewall_stopped(event = %FirewallStoppedEvent{}) do
    event.gateway_id
    |> ProcessQuery.get_processes_of_type_targeting_server("cracker")
    |> processes_changeset(event.version)
    |> repo_update_all()
    |> notify_top()
  end

  @spec processes_changeset([Process.t], non_neg_integer) ::
    [Changeset.t]
  defp processes_changeset(processes, version) do
    Enum.map(processes, fn process ->
      objective = CrackerBruteforce.objective(process.process_data, version)

      Process.update_changeset(process, %{objective: objective})
    end)
  end

  @spec repo_update_all([Changeset.t]) ::
    {:ok, MapSet.t(Server.id)}
  # Updates each changeset and accumulates uniquely their gateway
  defp repo_update_all(changesets) do
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
  # Notifies each top from the now-updated crackers to recalculate everything as
  # the objective changed
  defp notify_top({:ok, gateways}),
    do: Enum.each(gateways, &ProcessAction.reset_processes_on_server/1)
end
