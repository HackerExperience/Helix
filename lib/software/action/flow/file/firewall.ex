defmodule Helix.Software.Action.Flow.File.Firewall do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Process.Model.Process
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Server.Model.Server
  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Model.File
  alias Helix.Software.Model.SoftwareType.Firewall.Passive, as: FirewallPassive

  alias Helix.Software.Model.SoftwareType.Firewall.FirewallStartedEvent

  @type params :: %{}
  @type on_execute_error :: ProcessAction.on_create_error

  @spec execute_firewall(File.t_of_type(:firewall), Server.id, params) ::
    {:ok, Process.t}
    | on_execute_error
  def execute_firewall(file, server, _params) do
    file = FileInternal.load_modules(file)
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
end
