# FIXME: OTP20
defmodule Software.LogForge.ProcessType do

  @enforce_keys [:target_log_id, :version, :message, :entity_id]
  defstruct [:target_log_id, :version, :message, :entity_id]

  defimpl Helix.Process.Model.Process.ProcessType do

    alias Ecto.Changeset
    alias Helix.Software.Model.SoftwareType.LogForge.ProcessConclusionEvent

    @ram_base_factor 100

    def dynamic_resources(_),
      do: [:cpu]

    def minimum(%{version: v}),
      do: %{
        paused: %{
          ram: v * @ram_base_factor
        },
        running: %{
          ram: v * @ram_base_factor
        }
    }

    def kill(_, process, _),
      do: {%{Changeset.change(process)| action: :delete}, []}

    def state_change(data, process, _, :complete) do
      process = %{Changeset.change(process)| action: :delete}

      event = %ProcessConclusionEvent{
        target_log_id: data.target_log_id,
        version: data.version,
        message: data.message,
        entity_id: data.entity_id
      }

      {process, [event]}
    end

    def state_change(_, process, _, _),
      do: {process, []}

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)
  end

  defimpl Helix.Process.API.View.Process do

    alias Helix.Entity.Model.Entity
    alias Helix.Log.Model.Log
    alias Helix.Network.Model.Connection
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Process.Model.Process
    alias Helix.Process.Model.Process.Resources
    alias Helix.Process.Model.Process.State

    @spec render(map, Process.t, Server.id, Entity.id) ::
      %{
        :process_id => Process.id,
        :gateway_id => Server.id,
        :target_server_id => Server.id,
        :network_id => Network.id | nil,
        :connection_id => Connection.id | nil,
        :process_type => term,
        :target_log_id => Log.id,
        optional(:state) => State.state,
        optional(:objective) => Resources.t,
        optional(:processed) => Resources.t,
        optional(:allocated) => Resources.t,
        optional(:priority) => 0..5,
        optional(:creation_time) => DateTime.t,
        optional(:version) => non_neg_integer
      }
    def render(data, process = %{gateway_id: server}, server, _),
      do: render_local(data, process)
    def render(data = %{entity_id: entity}, process, _, entity),
      do: render_local(data, process)
    def render(data, process, _, _),
      do: render_remote(data, process)

    defp render_local(data, process) do
      base = take_data_from_process(process, :local)
      complement = %{
        target_log_id: data.target_log_id,
        version: data.version
      }

      Map.merge(base, complement)
    end

    defp render_remote(data, process) do
      base = take_data_from_process(process, :remote)
      complement = %{
        target_log_id: data.target_log_id
      }

      Map.merge(base, complement)
    end

    defp take_data_from_process(process, :remote) do
      %{
        process_id: process.process_id,
        gateway_id: process.gateway_id,
        target_server_id: process.target_server_id,
        network_id: process.network_id,
        connection_id: process.connection_id,
        process_type: process.process_type,
      }
    end

    defp take_data_from_process(process, :local) do
      %{
        process_id: process.process_id,
        gateway_id: process.gateway_id,
        target_server_id: process.target_server_id,
        network_id: process.network_id,
        connection_id: process.connection_id,
        process_type: process.process_type,
        state: process.state,
        objective: process.objective,
        processed: process.processed,
        allocated: process.allocated,
        priority: process.priority,
        creation_time: process.creation_time
      }
    end
  end
end
