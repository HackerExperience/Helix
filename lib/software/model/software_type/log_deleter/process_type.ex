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
end
