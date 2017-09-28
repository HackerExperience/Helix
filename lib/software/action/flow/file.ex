defmodule Helix.Software.Action.Flow.File do

  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Software.Action.Flow.Software.Cracker, as: CrackerFlow
  alias Helix.Software.Action.Flow.Software.Firewall, as: FirewallFlow
  alias Helix.Software.Action.Flow.Software.LogForger, as: LogForgerFlow
  alias Helix.Software.Model.File

  @type params ::
    CrackerFlow.params
    | FirewallFlow.params
    | LogForgerFlow.params

  @type execution_errors ::
    CrackerFlow.on_execute_error
    | FirewallFlow.on_execute_error
    | LogForgerFlow.on_execute_error

  @type meta ::
    CrackerFlow.meta
    | %{}

  @type error ::
    {:error, :notexecutable}
    | execution_errors

  @spec execute_file(File.t, Server.id, params, meta) ::
    {:ok, Process.t}
    | error
  @doc """
  Starts the process defined by `file` on `server`.

  If `file` is not an executable software, returns `{:error, :notexecutable}`.

  If the process can not be started on the server, returns the respective error.
  """
  def execute_file(file = %File{}, server, params, meta \\ %{}) do
    case file do
      %File{software_type: :cracker} ->
        CrackerFlow.execute_cracker(file, server, params, meta)
      %File{software_type: :firewall} ->
        FirewallFlow.execute_firewall(file, server, params)
      %File{software_type: :log_forger} ->
        LogForgerFlow.execute_log_forger(file, server, params)
      %File{} ->
        {:error, :notexecutable}
    end
  end
end
