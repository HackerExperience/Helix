defmodule Helix.Software.Model.SoftwareType.Firewall.Passive do

  @type t :: %__MODULE__{
    version: pos_integer
  }

  @enforce_keys [:version]
  defstruct [:version]

  defimpl Helix.Process.Model.Process.ProcessType do

    alias Helix.Software.Model.SoftwareType.Firewall.FirewallStartedEvent
    alias Helix.Software.Model.SoftwareType.Firewall.FirewallStoppedEvent

    @ram_base_factor 5
    @cpu_base_factor 2

    def dynamic_resources(_),
      do: []

    def minimum(%{version: v}),
      do: %{
        paused: %{
          ram: v * @ram_base_factor
        },
        running: %{
          ram: v * @ram_base_factor,
          cpu: v * @cpu_base_factor
        }
      }

    def kill(data, process, _) do
      process =
        process
        |> Ecto.Changeset.change()
        |> Map.put(:action, :delete)

      event = %FirewallStoppedEvent{
        version: data.version,
        gateway_id: Ecto.Changeset.get_field(process, :gateway_id)
      }

      {process, [event]}
    end

    def state_change(data, process, :running, :paused) do
      event = %FirewallStoppedEvent{
        version: data.version,
        gateway_id: Ecto.Changeset.get_field(process, :gateway_id)
      }

      {process, [event]}
    end

    def state_change(data, process, :paused, :running) do
      event = %FirewallStartedEvent{
        version: data.version,
        gateway_id: Ecto.Changeset.get_field(process, :gateway_id)
      }

      {process, [event]}
    end

    def state_change(_, process, _, _),
      do: {process, []}

    def conclusion(_, _),
      do: raise "firewall(passive) process should not be 'completed'"
  end

  defimpl Helix.Process.API.View.Process do

    def render(data, process, _, _) do
      %{
        process_id: process.process_id,
        gateway_id: process.gateway_id,
        process_type: process.type,
        state: process.state,
        allocated: process.allocated,
        priority: process.priority,
        creation_time: process.creation_time,
        version: data.version
      }
    end
  end
end
