defmodule Helix.Software.Action.Flow.File do

  alias Helix.Event
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File

  alias Helix.Software.Process.Cracker.Bruteforce, as: BruteforceProcess
  alias Helix.Software.Process.File.Install, as: FileInstallProcess

  @type params ::
    BruteforceProcess.creation_params
    | FileInstallProcess.creation_params

  @type meta ::
    BruteforceProcess.Executable.meta
    | FileInstallProcess.Executable.meta

  @type executable_errors ::
    bruteforce_execution_error
    | file_install_execution_error

  # Accumulation of all possible executable errors. The types below are useful
  # for caller methods, who are interested in knowing the possible return types
  # without having to alias the corresponding Process (which is an
  # implementation detail).
  @type bruteforce_execution_error :: BruteforceProcess.executable_error
  @type file_install_execution_error :: FileInstallProcess.executable_error

  @type executable ::
    {File.t, File.Module.name}
    | :generic_install

  @typep relay :: Event.relay

  @spec execute_file(executable, Server.t, Server.t, params, meta | term, relay) ::
    {:ok, Process.t}
    | executable_errors
    | {:error, :not_executable}
  @doc """
  Starts the process defined by `file` on `server`. Since a File may have
  multiple different modules, and each module has its own execution logic, the
  caller must also specify the desired module to be executed.

  A generically executable file may be passed, in which case it automatically
  hands it to the generic FileInstallProcess.

  If `file` is not an executable software, returns `{:error, :not_executable}`.

  If the process can not be started on the server, returns the corresponding
  error.
  """
  def execute_file(
    executable, gateway = %Server{}, target = %Server{}, params, meta, relay)
  do
    case executable do
      {%File{software_type: :cracker}, :bruteforce} ->
        BruteforceProcess.execute(gateway, target, params, meta, relay)

      # %File{software_type: :firewall} ->
      #   FirewallFlow.execute(file, server, params)
      # %File{software_type: :log_forger} ->
      #   LogForgerFlow.execute(file, server, params)

      {%File{}, _} ->
        {:error, :not_executable}

      :generic_install ->
        FileInstallProcess.execute(gateway, target, params, meta, relay)
    end
  end
end
