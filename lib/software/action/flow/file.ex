defmodule Helix.Software.Action.Flow.File do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Process.Model.Process
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Server.Model.Server
  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Software.Model.File
  alias Helix.Software.Model.SoftwareType.Firewall.Passive, as: FirewallPassive
  alias Helix.Software.Model.SoftwareType.LogForge

  alias Helix.Software.Model.SoftwareType.Firewall.FirewallStartedEvent

  @doc """
  Starts the process defined by `file` on `server`.

  If `file` is not an executable software, returns `{:error, :notexecutable}`.

  If the process can not be started on the server, returns the respective error.
  """
  def execute_file(file = %File{}, server, params \\ %{}) do
    server = Server.ID.cast!(server)

    case file do
      %File{software_type: :firewall} ->
        firewall(file, server, params)
      %File{software_type: :log_forger} ->
        log_forger(file, server, params)
      %File{} ->
        {:error, :notexecutable}
    end
  end

  @spec firewall(File.t_of_type(:firewall), Server.id, map) ::
    term
  defp firewall(file, server, _) do
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
      with {:ok, process, p_events} <- ProcessAction.create(params) do
        event = %FirewallStartedEvent{
          gateway_id: server,
          version: version
        }

        Event.emit(p_events)
        Event.emit(event)
        {:ok, process}
      end
    end
  end

  @spec log_forger(File.t_of_type(:log_forger), Server.id, LogForge.create_params) ::
    {:ok, Process.t}
    | ProcessAction.on_create_error
    | {:error, {:log, :notfound}}
    | {:error, Ecto.Changeset.t}
  defp log_forger(file, server, params) do
    with \
      {:ok, data} <- log_forger_prepare(file, params),
      {:ok, process_params} <- log_forger_process_params(file, server, data),
      {:ok, process, events} <- ProcessAction.create(process_params)
    do
      Event.emit(events)
      {:ok, process}
    end
  end

  defp log_forger_prepare(file, params) do
    modules = FileQuery.get_modules(file)
    LogForge.create(params, modules)
  end

  defp log_forger_process_params(file, server, data = %{operation: "edit"}) do
    with \
      log_id = data.target_log_id,
      log = %{} <- LogQuery.fetch(log_id) || {:error, {:log, :notfound}}
    do
      revision_count = LogQuery.count_revisions_of_entity(log, data.entity_id)
      objective = LogForge.edit_objective(data, log, revision_count)

      process_params = %{
        gateway_id: server,
        target_server_id: log.server_id,
        file_id: file.file_id,
        objective: objective,
        process_data: data,
        process_type: "log_forger"
      }

      {:ok, process_params}
    end
  end

  defp log_forger_process_params(file, server, data = %{operation: "create"}) do
    objective = LogForge.create_objective(data)

    process_params = %{
      gateway_id: server,
      target_server_id: data.target_server_id,
      file_id: file.file_id,
      objective: objective,
      process_data: data,
      process_type: "log_forger"
    }

    {:ok, process_params}
  end
end
