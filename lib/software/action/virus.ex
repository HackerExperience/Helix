defmodule Helix.Software.Action.Virus do

  alias Helix.Entity.Model.Entity
  alias Helix.Software.Internal.Virus, as: VirusInternal
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Virus

  alias Helix.Software.Event.Virus.Installed, as: VirusInstalledEvent
  alias Helix.Software.Event.Virus.InstallFailed, as: VirusInstallFailedEvent

  @spec install(File.t, Entity.id) ::
    {:ok, Virus.t, [VirusInstalledEvent.t]}
    | {:error, VirusInstallFailedEvent.reason, [VirusInstallFailedEvent.t]}
  def install(file, entity_id) do
    case VirusInternal.install(file, entity_id) do
      {:ok, virus} ->
        event = VirusInstalledEvent.new(file, virus)

        {:ok, virus, [event]}

      {:error, reason} ->
        event = VirusInstallFailedEvent.new(file, entity_id, reason)

        {:error, reason, [event]}
    end
  end
end
