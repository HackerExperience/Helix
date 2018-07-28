defmodule Helix.Software.Event.Virus do

  import Helix.Event

  event Collected do
    @moduledoc """
    `VirusCollectedEvent` is fired right after the earnings of the virus have
    been collected and transferred to the player's bank account/bitcoin wallet.
    """

    alias Helix.Universe.Bank.Model.BankAccount
    alias Helix.Software.Model.Virus

    event_struct [:virus, :earnings, :bank_account, :wallet]

    @type t ::
      %__MODULE__{
        virus: Virus.t,
        earnings: Virus.earnings,
        bank_account: BankAccount.t | nil,
        wallet: term | nil
      }

    @spec new(Virus.t, Virus.earnings, Virus.payment_info) ::
      t
    def new(virus = %Virus{}, earnings, {bank_acc, wallet}) do
      %__MODULE__{
        virus: virus,
        earnings: earnings,
        bank_account: bank_acc,
        wallet: wallet
      }
    end

    publish do
      @moduledoc """
      Publishing that a virus has been collected enables the client to reset the
      running time of the virus.
      """

      @event :virus_collected

      @doc false
      def generate_payload(event = %{}, _socket) do
        data =
          event
          |> payment_data()
          |> Map.merge(%{file_id: to_string(event.virus.file_id)})

        {:ok, data}
      end

      defp payment_data(event = %{bank_account: %BankAccount{}}) do
        %{
          atm_id: to_string(event.bank_account.atm_id),
          account_number: event.bank_account.account_number,
          money: event.earnings
        }
      end

      @doc false
      def whom_to_publish(event),
        do: %{account: event.virus.entity_id}
    end
  end

  event Installed do
    @moduledoc """
    `VirusInstalledEvent` is fired when a virus has been installed by someone.
    It's one of the two possible results of FileInstallProcessedEvent (when the
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

    publish do
      @moduledoc """
      Publishes to the client that the virus was successfully installed.
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
      We only publish to the player who installed the virus.
      """
      def whom_to_publish(event),
        do: %{account: event.entity_id}
    end

    loggable do

      @doc """
        Gateway: "localhost installed virus $file_name at $first_ip"
        Endpoint: "$last_ip installed virus $file_name at localhost"
      """
      log(event) do
        process = get_process(event)
        file_name = get_file_name(event.file)

        log_map %{
          event: event,
          entity_id: event.entity_id,
          gateway_id: process.gateway_id,
          endpoint_id: process.target_id,
          network_id: process.network_id,
          type_gateway: :virus_installed_gateway,
          data_gateway: %{ip: "$first_ip"},
          type_endpoint: :virus_installed_endpoint,
          data_endpoint: %{ip: "$last_ip"},
          data_both: %{network_id: process.network_id, file_name: file_name}
        }
      end

    end
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

    publish do
      @moduledoc """
      Publishes to the Client that the virus was not installed for some `reason`
      """

      @event :virus_install_failed

      def generate_payload(event, _socket) do
        data = %{
          reason: to_string(event.reason)
        }

        {:ok, data}
      end

      @doc """
      We only publish to the player who tried to install the virus.
      """
      def whom_to_publish(event),
        do: %{account: event.entity_id}
    end
  end
end
