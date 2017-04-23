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
end
