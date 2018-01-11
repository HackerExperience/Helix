defmodule Helix.Software.Event.Handler.Virus do

  alias Helix.Event

  alias Helix.Software.Action.Virus, as: VirusAction

  alias Helix.Software.Event.File.Install.Processed,
    as: FileInstallProcessedEvent

  @doc """
  Handles the completion of FileInstallProcess when the target file is a virus.

  Performs a noop if the target file is not a virus.

  Emits: VirusInstalledEvent.t, VirusInstallFailedEvent.t
  """
  def virus_installed(event = %FileInstallProcessedEvent{backend: :virus}) do
    case VirusAction.install(event.file, event.entity_id) do
      {:ok, virus, events} ->
        Event.emit(events, from: event)

        {:ok, virus}

      {:error, reason, events} ->
        Event.emit(events, from: event)

        {:error, reason}
    end
  end
  def virus_installed(%FileInstallProcessedEvent{backend: _}),
    do: :noop
end
