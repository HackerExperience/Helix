defmodule Helix.Software.Service.Flow.File do

  alias Helix.Event
  alias Helix.Process.Service.API.Process
  alias Helix.Software.Controller.File, as: FileController
  alias Helix.Software.Model.File
  alias Helix.Software.Model.SoftwareType.Firewall.FirewallStarted
  alias Software.Firewall.ProcessType.Passive, as: FirewallPassive

  import HELF.Flow

  @spec execute_file(File.t, HELL.PK.t, Keyword.t) ::
    {:ok, process :: term}
    | {:error, :notexecutable}
    | {:error, :resources}
    | {:error, Ecto.Changeset.t}
  @doc """
  Starts the process defined by `file` on `server`

  If `file` is not an executable software, returns `{:error, :notexecutable}`.

  If the process can not be started on the server, returns the respective error
  """
  def execute_file(file, server, params \\ []) do
    start_file_process(file, server, params)
  end

  defp start_file_process(file = %File{software_type: :firewall}, server, _) do
    %{firewall_passive: version} = FileController.get_modules(file)
    process_data = %FirewallPassive{version: version}

    params = %{
      gateway_id: server,
      target_server_id: server,
      file_id: file.file_id,
      process_data: process_data,
      process_type: "firewall_passive"
    }

    flowing do
      with {:ok, process} <- Process.create(params) do
        event = %FirewallStarted{
          gateway_id: server,
          version: version
        }

        Event.emit(event)
        {:ok, process}
      end
    end
  end

  defp start_file_process(_, _, _) do
    {:error, :notexecutable}
  end
end
