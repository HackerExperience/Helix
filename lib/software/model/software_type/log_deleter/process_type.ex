# FIXME: OTP20
# TODO: Remove me when implementing LogForge and LogRecover
defmodule Software.LogDeleter.ProcessType do

  @enforce_keys [:target_log_id]
  defstruct [:target_log_id]

  defimpl Helix.Process.Model.Process.ProcessType do

    alias Helix.Software.Model.SoftwareType.LogDeleter.ProcessConclusionEvent

    @ram_base_factor 100

    def dynamic_resources(_),
      do: [:cpu]

    def minimum(%{software_version: v}),
      do: %{
        paused: %{
          ram: v * @ram_base_factor
        },
        running: %{
          ram: v * @ram_base_factor
        }
    }

    def conclusion(data, process) do
      process =
        process
        |> Ecto.Changeset.change()
        |> Map.put(:action, :delete)

      event = %ProcessConclusionEvent{
        target_log_id: data.target_log_id
      }

      {process, [event]}
    end
  end

  defimpl Helix.Process.Public.ProcessView do

    alias Helix.Process.Model.Process
    alias Helix.Process.Model.Process.Resources
    alias Helix.Process.Model.Process.State

    @spec render(map, Process.t, HELL.PK.t, HELL.PK.t) ::
      %{
        :process_id => HELL.PK.t,
        :gateway_id => HELL.PK.t,
        :target_server_id => HELL.PK.t,
        :network_id => HELL.PK.t | nil,
        :connection_id => HELL.PK.t | nil,
        :process_type => term,
        :target_log_id => HELL.PK.t,
        optional(:state) => State.state,
        optional(:objective) => Resources.t,
        optional(:processed) => Resources.t,
        optional(:allocated) => Resources.t,
        optional(:priority) => 0..5,
        optional(:creation_time) => DateTime.t,
        optional(:software_version) => non_neg_integer,
        optional(:scope) => String.t
      }
    def render(data, process = %{gateway_id: server}, server, _) do
      base = take_data_from_process(process)
      complement = %{
        target_log_id: data.target_log_id
      }

      Map.merge(base, complement)
    end

    def render(data, process, _, _) do
      base =
        process
        |> take_data_from_process()
        |> Map.drop([
          :state,
          :objective,
          :processed,
          :allocated,
          :priority,
          :creation_time
        ])

      complement = %{
        target_log_id: data.target_log_id
      }

      Map.merge(base, complement)
    end

    defp take_data_from_process(process) do
      %{
        process_id: id,
        gateway_id: gateway,
        target_server_id: target,
        network_id: net,
        connection_id: connection,
        process_type: type,
        state: state,
        objective: objective,
        processed: processed,
        allocated: allocated,
        priority: priority,
        creation_time: creation} = process

      %{
        process_id: id,
        gateway_id: gateway,
        target_server_id: target,
        network_id: net,
        connection_id: connection,
        process_type: type,
        state: state,
        objective: objective,
        processed: processed,
        allocated: allocated,
        priority: priority,
        creation_time: creation
      }
    end
  end
end
