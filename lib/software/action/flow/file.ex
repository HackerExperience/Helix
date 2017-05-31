defmodule Helix.Software.Action.Flow.File do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Software.Model.File
  alias Helix.Software.Model.SoftwareType.Firewall.FirewallStartedEvent
  alias Software.Firewall.ProcessType.Passive, as: FirewallPassive
  alias Software.LogForge.ProcessType, as: LogForge

  @spec execute_file(File.t, Server.id, map) ::
    {:ok, Process.t}
    | {:error, :notexecutable}
    | {:error, :resources}
    | {:error, Ecto.Changeset.t}
  @doc """
  Starts the process defined by `file` on `server`

  If `file` is not an executable software, returns `{:error, :notexecutable}`.

  If the process can not be started on the server, returns the respective error
  """
  def execute_file(file, server, params \\ %{}),
    do: start_file_process(file, server, params)

  defp start_file_process(file = %File{software_type: :firewall}, server, _) do
    %{firewall_passive: version} = FileQuery.get_modules(file)
    process_data = %FirewallPassive{version: version}

    params = %{
      gateway_id: server,
      target_server_id: server,
      file_id: file.file_id,
      process_data: process_data,
      process_type: "firewall_passive"
    }

    flowing do
      with {:ok, process} <- ProcessAction.create(params) do
        event = %FirewallStartedEvent{
          gateway_id: server,
          version: version
        }

        Event.emit(event)
        {:ok, process}
      end
    end
  end

  defp start_file_process(
    file = %File{software_type: :log_forge},
    server,
    params = %{target_log_id: _, message: _, entity_id: _})
  do
    %{log_forger_edit: version} = FileQuery.get_modules(file)
    process_data = %LogForge{
      target_log_id: params.target_log_id,
      message: params.message,
      entity_id: params.entity_id,
      version: version
    }

    target_log = LogQuery.fetch(params.target_log_id)
    revision_count = LogQuery.count_revisions_of_entity(
      target_log,
      params.entity_id)

    cost_factor = if params.entity_id == target_log.entity_id do
      # The first revision should not increase the total WUs to edit the log
      revision_count
    else
      revision_count + 1
    end

    # TODO: move this to the log forge module
    objective = %{
      cpu: factorial(cost_factor) * 12_500
    }

    process_params = %{
      gateway_id: server,
      target_server_id: target_log.server_id,
      file_id: file.file_id,
      objective: objective,
      process_data: process_data,
      process_type: "log_forge"
    }

    ProcessAction.create(process_params)
  end

  defp start_file_process(_, _, _) do
    {:error, :notexecutable}
  end

  defp factorial(n),
    do: Enum.reduce(1..n, &(&1 * &2))
end
