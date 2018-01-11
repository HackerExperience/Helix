defmodule Helix.Software.Event.Virus do

  import Helix.Event

  event Installed do
    @moduledoc """
    `VirusInstalledEvent` is fired when a virus has been installed by someone.
    It one of the two possible results of FileInstallProcessedEvent (when the
    file is a virus), with the other being `VirusInstallFailedEvent`.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Software.Model.File
    alias Helix.Software.Model.Virus

    event_struct [:file, :virus, :entity_id]

    @type t ::
      %__MODULE__{
        file: File.t,
        virus: Virus.t,
        entity_id: Entity.id
      }

    @spec new(File.t, Virus.t) ::
      t
    def new(file = %File{}, virus = %Virus{}) do
      %__MODULE__{
        file: file,
        virus: virus,
        entity_id: virus.entity_id
      }
    end

    notify do
      @moduledoc """
      Notifies the client that the virus was successfully installed
      """

      alias Helix.Software.Public.Index, as: SoftwareIndex

      @event :virus_installed

      def generate_payload(event, _socket) do
        data = %{
          file: SoftwareIndex.render_file(event.file)
        }

        {:ok, data}
      end

      @doc """
      We only notify the player who installed the virus.
      """
      def whom_to_notify(event),
        do: %{account: event.entity_id}
    end

    # TODO: Log that player has installed virus. #369
  end

  event InstallFailed do
    @moduledoc """
    `VirusInstallFailedEvent` is fired when the player attempted to install a
    virus but failed for some reason.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Software.Model.File

    event_struct [:file, :entity_id, :reason]

    @type t ::
      %__MODULE__{
        file: File.t,
        entity_id: Entity.id,
        reason: reason
      }

    @type reason :: :internal

    @spec new(File.t, Entity.id, reason) ::
      t
    def new(file = %File{}, entity_id = %Entity.ID{}, reason) do
      %__MODULE__{
        file: file,
        entity_id: entity_id,
        reason: reason
      }
    end

    notify do
      @moduledoc """
      Notifies the client that the virus was not installed for some `reason`
      """

      @event :virus_install_failed

      def generate_payload(event, _socket) do
        data = %{
          reason: to_string(event.reason)
        }

        {:ok, data}
      end

      @doc """
      We only notify the player who tried to install the virus.
      """
      def whom_to_notify(event),
        do: %{account: event.entity_id}
    end
  end
end
