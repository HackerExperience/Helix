defmodule Helix.Software.Action.Virus do

  alias Helix.Entity.Model.Entity
  alias Helix.Software.Internal.Virus, as: VirusInternal
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Virus
  alias Helix.Software.Query.Virus, as: VirusQuery

  alias Helix.Software.Event.Virus.Collected, as: VirusCollectedEvent
  alias Helix.Software.Event.Virus.Installed, as: VirusInstalledEvent
  alias Helix.Software.Event.Virus.InstallFailed, as: VirusInstallFailedEvent

  @spec install(File.t, Entity.id) ::
    {:ok, Virus.t, [VirusInstalledEvent.t]}
    | {:error, VirusInstallFailedEvent.reason, [VirusInstallFailedEvent.t]}
  def install(file, entity_id) do
    case VirusInternal.install(file, entity_id) do
      {:ok, virus} ->
        {:ok, virus, [VirusInstalledEvent.new(file, virus)]}

      {:error, reason} ->
        {:error, reason, [VirusInstallFailedEvent.new(file, entity_id, reason)]}
    end
  end

  @spec collect(File.t, Virus.payment_info) ::
    {:ok, [VirusCollectedEvent.t]}
    | {:error, []}
  @doc """
  Collects the earnings of the virus (identified by `file`) and transfers them
  to the address in `payment_info`.
  """
  def collect(file, payment_info) do
    virus = VirusQuery.fetch(file.file_id)

    with \
      earnings = Virus.calculate_earnings(file, virus, []),
      true <- is_integer(earnings),
      {:ok, _} <- VirusInternal.set_running_time(virus, 0)
    do
      {:ok, [VirusCollectedEvent.new(virus, earnings, payment_info)]}
    else
      _ ->
        {:error, []}
    end
  end
end
