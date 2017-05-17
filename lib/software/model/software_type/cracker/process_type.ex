# FIXME: OTP20
defmodule Software.Cracker.ProcessType do

  @enforce_keys ~w/
    entity_id
    network_id
    target_server_ip
    target_server_id
    server_type
    software_version/a
  defstruct ~w/
    entity_id
    network_id
    target_server_ip
    target_server_id
    server_type
    software_version/a

  defimpl Helix.Process.Model.Process.ProcessType do

    alias Helix.Software.Model.SoftwareType.Cracker.ProcessConclusionEvent

    @ram_base 300

    def dynamic_resources(_),
      do: [:cpu]

    # TODO: I think that linear growth might not be best bet
    def minimum(%{software_version: v}) do
      %{
        paused: %{ram: v * @ram_base},
        running: %{ram: v * @ram_base}
      }
    end

    def conclusion(data, process) do
      process =
        process
        |> Ecto.Changeset.change()
        |> Map.put(:action, :delete)

      event = %ProcessConclusionEvent{
        entity_id: data.entity_id,
        network_id: data.network_id,
        server_id: data.target_server_id,
        server_ip: data.target_server_ip,
        server_type: data.server_type
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
        :network_id => HELL.PK.t,
        :connection_id => HELL.PK.t,
        :process_type => term,
        optional(:state) => State.state,
        optional(:allocated) => Resources.t,
        optional(:priority) => 0..5,
        optional(:creation_time) => DateTime.t,
        optional(:software_version) => non_neg_integer,
        optional(:target_server_ip) => HELL.IPv4.t
      }
    def render(data, process = %{gateway_id: server}, server, _) do
      base = take_data_from_process(process)
      complement = %{
        software_version: data.software_version,
        target_server_ip: data.target_server_ip
      }

      Map.merge(base, complement)
    end

    def render(data = %{entity_id: entity}, process, _, entity) do
      base = take_data_from_process(process)
      complement = %{
        software_version: data.software_version,
        target_server_ip: data.target_server_ip
      }

      Map.merge(base, complement)
    end

    def render(_, process, _, _) do
      process
      |> take_data_from_process()
      |> Map.drop([:state, :allocated, :priority, :creation_time])
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
        allocated: allocated,
        priority: priority,
        creation_time: creation
      }
    end
  end
end
