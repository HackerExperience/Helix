defmodule Helix.Software.Action.Flow.File do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Server.Model.Server
  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Software.Model.File
  alias Helix.Software.Model.SoftwareType.Firewall.FirewallStartedEvent
  alias Software.Firewall.ProcessType.Passive, as: FirewallPassive
  alias Helix.Software.Model.SoftwareType.LogForge

  @doc """
  Starts the process defined by `file` on `server`

  If `file` is not an executable software, returns `{:error, :notexecutable}`.

  If the process can not be started on the server, returns the respective error
  """
  def execute_file(file = %File{}, server, params \\ %{}),
    do: start_file_process(file, server, params)

  @spec start_file_process(%File{software_type: :firewall}, Server.idt, map) ::
    Helix.Process.Action.Process.on_create
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

  @spec start_file_process(%File{software_type: :log_forger}, Server.idt, LogForge.create_params) ::
    ProcessAction.on_create
    | {:error, {:log, :notfound}}
    | {:error, Ecto.Changeset.t}
  defp start_file_process(
    file = %File{software_type: :log_forger},
    server,
    params)
  do
    with \
      modules = FileQuery.get_modules(file),
      {:ok, process_data} <- LogForge.create(params, modules),
      log_id = process_data.target_log_id,
      target_log = %{} <- LogQuery.fetch(log_id) || {:error, {:log, :notfound}}
    do
      revision_count = LogQuery.count_revisions_of_entity(
        target_log,
        process_data.entity_id)
      objective = LogForge.objective(process_data, target_log, revision_count)

      process_params = %{
        gateway_id: server,
        target_server_id: target_log.server_id,
        file_id: file.file_id,
        objective: objective,
        process_data: process_data,
        process_type: "log_forger"
      }

      # TODO: emit process started event
      ProcessAction.create(process_params)
    end
  end

  defp start_file_process(_, _, _) do
    {:error, :notexecutable}
  end
end
