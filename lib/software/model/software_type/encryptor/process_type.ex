# FIXME: OTP20
defmodule Software.Encryptor.ProcessType do

  @enforce_keys [:storage_id, :target_file_id, :software_version]
  defstruct [:storage_id, :target_file_id, :software_version]

  defimpl Helix.Process.Model.Process.ProcessType do

    alias Helix.Software.Model.SoftwareType.Encryptor.ProcessConclusionEvent

    @ram_base_factor 100

    # The only value that is dynamic (ie: the more allocated, the faster the
    # process goes) is cpu
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

      events = event(data, process, :completed)

      {process, events}
    end

    def event(data, process, :completed) do
      event = %ProcessConclusionEvent{
        target_file_id: data.target_file_id,
        target_server_id: process.target_server_id,
        storage_id: data.storage_id,
        version: data.software_version
      }

      [event]
    end

    def event(_, _, _) do
      []
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
        :target_file_id => HELL.PK.t,
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
        target_file_id: data.target_file_id,
        software_version: data.software_version,
        scope: data.scope
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
        target_file_id: data.target_file_id
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
