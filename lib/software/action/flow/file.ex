defmodule Helix.Software.Action.Flow.File do

  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File

  alias Helix.Software.Process.Cracker.Bruteforce, as: BruteforceProcess

  @type params ::
    BruteforceProcess.creation_params

  @type executable_errors ::
    bruteforce_execution_error

  @type meta ::
    BruteforceProcess.Executable.meta

  # Accumulation of all possible executable errors. The types below are useful
  # for caller methods, who are interested in knowing the possible return types
  # without having to alias the corresponding Process (which is an
  # implementation detail).
  @type bruteforce_execution_error :: BruteforceProcess.executable_error

  @typep file_module :: File.Module.name

  @spec execute_file(File.t, file_module, Server.t, Server.t, params, meta) ::
    {:ok, Process.t}
    | executable_errors
    | {:error, :not_executable}
  @doc """
  Starts the process defined by `file` on `server`. Since a File may have
  multiple different modules, and each module has its own execution logic, the
  caller must also specify the desired module to be executed.

  If `file` is not an executable software, returns `{:error, :not_executable}`.

  If the process can not be started on the server, returns the corresponding
  error.
  """
  def execute_file(file = %File{}, module, gateway, target, params, meta) do
    case {file, module} do
      {%File{software_type: :cracker}, :bruteforce} ->
        BruteforceProcess.execute(gateway, target, params, meta)

      # %File{software_type: :firewall} ->
      #   FirewallFlow.execute(file, server, params)
      # %File{software_type: :log_forger} ->
      #   LogForgerFlow.execute(file, server, params)

      {%File{}, _} ->
        {:error, :not_executable}
    end
  end
end
