defmodule Helix.Software.Action.Flow.File.LogForger do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Process.Model.Process
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Server.Model.Server
  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Model.File
  alias Helix.Software.Model.SoftwareType.LogForge

  @type params :: LogForge.create_params
  @type on_execute_error ::
    ProcessAction.on_create_error
    | {:error, {:log, :notfound}}
    | {:error, Ecto.Changeset.t}

  @spec execute_log_forger(File.t_of_type(:log_forger), Server.id, params) ::
    {:ok, Process.t}
    | on_execute_error
  def execute_log_forger(file, server, params) do
    flowing do
      with \
        {:ok, data} <- prepare(file, params),
        {:ok, process_params} <- process_params(file, server, data),
        {:ok, process, events} <- ProcessAction.create(process_params),
        on_success(fn -> Event.emit(events) end)
      do
        {:ok, process}
      end
    end
  end

  @spec prepare(File.t_of_type(:log_forger), params) ::
    {:ok, LogForge.t}
    | {:error, Ecto.Changeset.t}
  defp prepare(file, params) do
    file
    |> FileInternal.load_modules()
    |> LogForge.create(params)
  end

  @spec process_params(File.t_of_type(:log_forger), Server.id, LogForge.t) ::
    {:ok, Process.create_params}
    | {:error, {:log, :notfound}}
  defp process_params(file, server_id, data = %{operation: :edit}) do
    with \
      log_id = data.target_log_id,
      log = %{} <- LogQuery.fetch(log_id) || {:error, {:log, :notfound}}
    do
      revision_count = LogQuery.count_revisions_of_entity(log, data.entity_id)
      objective = LogForge.edit_objective(data, log, revision_count)

      process_params = %{
        gateway_id: server_id,
        target_server_id: log.server_id,
        file_id: file.file_id,
        objective: objective,
        process_data: data,
        process_type: "log_forger"
      }

      {:ok, process_params}
    end
  end

  defp process_params(file, server, data = %{operation: :create}) do
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
