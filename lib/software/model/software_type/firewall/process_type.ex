# FIXME: OTP20
defmodule Software.Firewall.ProcessType do
  defmodule Passive do

    @enforce_keys [:version]
    defstruct [:version]

    defimpl Helix.Process.Model.Process.ProcessType do

      @ram_base_factor 300
      @cpu_base_factor 100

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

      def kill(_, process, _),
        do: {%{Ecto.Changeset.change(process)| action: :delete}, []}

      def state_change(_, process, _, _),
        do: {process, []}

      def conclusion(_, _),
        do: raise "firewall(passive) process should not be 'completed'"
    end

    defimpl Helix.Process.Public.ProcessView do

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
end
