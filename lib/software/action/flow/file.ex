defmodule Helix.Software.Action.Flow.File do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Process.Model.Process
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Server.Model.Server
  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Software.Model.File
  alias Helix.Software.Model.SoftwareType.Cracker
  alias Helix.Software.Model.SoftwareType.Firewall.Passive, as: FirewallPassive
  alias Helix.Software.Model.SoftwareType.LogForge

  alias Helix.Software.Model.SoftwareType.Firewall.FirewallStartedEvent

  @doc """
  Starts the process defined by `file` on `server`.

  If `file` is not an executable software, returns `{:error, :notexecutable}`.

  If the process can not be started on the server, returns the respective error.
  """
  def execute_file(file = %File{}, server, params) do
    server = Server.ID.cast!(server)

    case file do
      %File{software_type: :cracker} ->
        cracker(file, server, params)
      %File{software_type: :firewall} ->
        firewall(file, server, params)
      %File{software_type: :log_forger} ->
        log_forger(file, server, params)
      %File{} ->
        {:error, :notexecutable}
    end
  end

  @spec cracker(File.t_of_type(:cracker), Server.id, Cracker.create_params) ::
    {:ok, Process.t}
    | ProcessAction.on_create_error
    | {:error, Cracker.changeset}
  defp cracker(file, server, params) do
    flowing do
      with \
        {:ok, data, firewall} <- cracker_prepare(file, params),
        {:ok, process_params} <- cracker_process_params(data, server, firewall),
        {:ok, process, events} <- ProcessAction.create(process_params),
        on_success(fn -> Event.emit(events) end)
      do
        {:ok, process}
      end
    end
  end

  @spec cracker_prepare(File.t_of_type(:cracker), Cracker.create_params) ::
    {:ok, Cracker.t, non_neg_integer}
    | {:error, Cracker.changeset}
  defp cracker_prepare(file, params) do
    target_firewall = fn server_id ->
      ProcessQuery.get_running_processes_of_type_on_server(
        server_id,
        "firewall_passive")
    end

    with {:ok, cracker} <- file |> load_modules() |> Cracker.create(params) do
      case target_firewall.(cracker.target_server_id) do
        [] ->
          {:ok, cracker, 0}
        [%{process_data: %{version: v}}] ->
          {:ok, cracker, v}
      end
    end
  end

  @spec cracker_process_params(Cracker.t, Server.id, non_neg_integer) ::
    {:ok, Process.create_params}
  defp cracker_process_params(cracker, server_id, firewall) do
    params = %{
      gateway_id: server_id,
      target_server_id: cracker.target_server_id,
      network_id: cracker.network_id,
      objective: Cracker.objective(cracker, firewall),
      process_data: cracker,
      process_type: "cracker"
    }

    {:ok, params}
  end

  @spec firewall(File.t_of_type(:firewall), Server.id, map) ::
    {:ok, Process.t}
    | ProcessAction.on_create_error
  defp firewall(file, server, _) do
    file = load_modules(file)
    process_data = %FirewallPassive{version: file.file_modules.firewall_passive}

    params = %{
      gateway_id: server,
      target_server_id: server,
      file_id: file.file_id,
      process_data: process_data,
      process_type: "firewall_passive"
    }

    event = %FirewallStartedEvent{
      gateway_id: server,
      version: file.file_modules.firewall_passive
    }

    flowing do
      with \
        {:ok, process, p_events} <- ProcessAction.create(params),
        on_success(fn -> Event.emit(p_events) end),
        on_success(fn -> Event.emit(event) end)
      do
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
    flowing do
      with \
        {:ok, data} <- log_forger_prepare(file, params),
        {:ok, process_params} <- log_forger_process_params(file, server, data),
        {:ok, process, events} <- ProcessAction.create(process_params),
        on_success(fn -> Event.emit(events) end)
      do
        {:ok, process}
      end
    end
  end

  @spec log_forger_prepare(File.t_of_type(:log_forger), LogForge.create_params) ::
    {:ok, LogForge.t}
    | {:error, Ecto.Changeset.t}
  defp log_forger_prepare(file, params) do
    file
    |> load_modules()
    |> LogForge.create(params)
  end

  @spec log_forger_process_params(File.t_of_type(:log_forger), Server.id, LogForge.t) ::
    {:ok, Process.create_params}
    | {:error, {:log, :notfound}}
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

  # FIXME: this will be removed when file modules become just an attribute
  defp load_modules(file),
    do: %{file| file_modules: FileQuery.get_modules(file)}
end
