defmodule Helix.Test.Process.Data.Setup do
  @moduledoc """
  Attention! If you want integrated data, ensured to exist on all domains,
  use the corresponding `FlowSetup`, like `SoftwareFlowSetup`.

  Data generated here has the correct format, with the correct types, but by
  default generates only fake data.

  It's possible to specify real data with custom opts, but you'd need to ensure
  you've also specified the correct data for the process itself.
  (For instance, a valid FileTransferProcess would need a valid `storage_id`
  passed as data parameter, but also a valid `connection_id` and `file_id`
  passed as parameter for the process itself.)

  This is prone to error and, as such, you should use `*FlowSetup` instead.
  """

  # Processes
  alias Helix.Log.Process.Forge, as: LogForgeProcess
  alias Helix.Software.Process.Cracker.Bruteforce, as: CrackerBruteforce
  alias Helix.Software.Process.File.Transfer, as: FileTransferProcess
  alias Helix.Software.Process.File.Install, as: FileInstallProcess

  alias HELL.TestHelper.Random
  alias Helix.Test.Log.Helper, as: LogHelper
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Process.Helper.TOP, as: TOPHelper

  @doc """
  Chooses a random implementation and uses it. Beware that `data_opts`, used by
  `custom/3`, is always an empty list when called from `random/1`.
  """
  def random(meta) do
    custom_implementations()
    |> Enum.take_random(1)
    |> List.first()
    |> custom([], meta)
  end

  @doc """
  Opts for file_download:
  - type: Connection type. Either `:download` or `:pftp_download`.
  - storage_id: Set storage_id.
  """
  def custom(:file_download, data_opts, meta) do
    meta =
      if meta.gateway_id == meta.target_id do
        %{meta| target_id: ServerHelper.id()}
      else
        meta
      end

    src_connection_id = meta.src_connection_id || NetworkHelper.connection_id()
    tgt_file_id = meta.tgt_file_id || SoftwareHelper.id()

    connection_type = Keyword.get(data_opts, :type, :download)
    storage_id =
      Keyword.get(data_opts, :storage_id, SoftwareHelper.storage_id())

    data = %FileTransferProcess{
      type: :download,
      destination_storage_id: storage_id,
      connection_type: connection_type
    }

    meta =
      %{meta|
        tgt_file_id: tgt_file_id,
        src_connection_id: src_connection_id
      }

    objective =
      TOPHelper.Resources.objective(dlk: 500, network_id: meta.network_id)

    resources =
      %{
        l_dynamic: [:dlk],
        r_dynamic: [:ulk],
        static: TOPHelper.Resources.random_static(),
        objective: objective
      }

    {:file_download, data, meta, resources}
  end

  @doc """
  Opts for file_upload:
  - storage_id: Set storage_id.
  """
  def custom(:file_upload, data_opts, meta) do
    target_id =
      if meta.gateway_id == meta.target_id do
        ServerHelper.id()
      else
        meta.target_id
      end

    src_connection_id = meta.src_connection_id || NetworkHelper.connection_id()
    tgt_file_id = meta.tgt_file_id || SoftwareHelper.id()

    storage_id =
      Keyword.get(data_opts, :storage_id, SoftwareHelper.storage_id())

    data = %FileTransferProcess{
      type: :upload,
      destination_storage_id: storage_id,
      connection_type: :ftp
    }

    meta =
      %{meta|
        tgt_file_id: tgt_file_id,
        src_connection_id: src_connection_id,
        target_id: target_id
       }

    objective =
      TOPHelper.Resources.objective(ulk: 500, network_id: meta.network_id)

    resources =
      %{
        l_dynamic: [:ulk],
        r_dynamic: [:dlk],
        objective: objective,
        static: TOPHelper.Resources.random_static()
      }

    {:file_upload, data, meta, resources}
  end

  @doc """
  Opts for bruteforce:
  - target_server_ip: Set target server IP.
  - real_ip: Whether to use the server real IP. Defaults to false.

  All others are automatically derived from process meta data.
  """
  def custom(:bruteforce, data_opts, meta) do
    target_server_ip =
      cond do
        data_opts[:target_server_ip] ->
          data_opts[:target_server_ip]

        data_opts[:real_ip] ->
          raise "todo"

        true ->
          Random.ipv4()
      end

    src_file_id = meta.src_file_id || SoftwareHelper.id()

    data = CrackerBruteforce.new(%{target_server_ip: target_server_ip}, %{})

    meta = %{meta| src_file_id: src_file_id}

    resources =
      %{
        l_dynamic: [:cpu],
        r_dynamic: [],
        static: TOPHelper.Resources.random_static(),
        objective: TOPHelper.Resources.objective(cpu: 500)
      }

    {:cracker_bruteforce, data, meta, resources}
  end

  @doc """
  Probably does not work
  """
  def custom(:install_virus, _data_opts, meta) do
    src_connection_id = meta.src_connection_id || NetworkHelper.connection_id()
    tgt_file_id = meta.tgt_file_id || SoftwareHelper.id()

    data = FileInstallProcess.new(%{backend: :virus}, %{})

    meta =
      meta
      |> put_in([:tgt_file_id], tgt_file_id)
      |> put_in([:src_connection_id], src_connection_id)

    resources =
      %{
        l_dynamic: [:cpu],
        r_dynamic: [],
        static: TOPHelper.Resources.random_static(),
        objective: TOPHelper.Resources.objective(cpu: 5000)
      }

    {:install_virus, data, meta, resources}
  end

  @doc """
  `:log_forge` process will randomly select either `edit` or `create` operation.
  """
  def custom(:log_forge, data_opts, meta) do
    [:log_forge_edit, :log_forge_create]
    |> Enum.random()
    |> custom(data_opts, meta)
  end

  @doc """
  Opts for `log_forge_edit:`
  - tgt_log_id: Which log to edit. Won't generate a real one.
  - log_info: Tuple with log type and data
  - forger_version: Set forger version. Defaults to 100.

  All others are automatically derived from process meta data.
  """
  def custom(:log_forge_edit, data_opts, meta),
    do: custom_log_forge({:log_forge_edit, :edit}, data_opts, meta)

  @doc """
  Opts for `log_forge_create`:
  - log_info: Tuple with log type and data.
  - forger_version: Set forger version. Defaults to 100.
  """
  def custom(:log_forge_create, data_opts, meta),
    do: custom_log_forge({:log_forge_create, :create}, data_opts, meta)

  defp custom_log_forge({process_type, action}, data_opts, meta) do
    target_id = meta.target_id
    entity_id = meta.source_entity_id
    version = Keyword.get(data_opts, :forger_version, 100)
    src_file_id = meta.src_file_id || SoftwareHelper.id()
    {log_type, log_data} =
      Keyword.get(data_opts, :log_info, LogHelper.log_info())

    data =
      %LogForgeProcess{
        log_type: log_type,
        log_data: log_data,
        forger_version: version
      }

    resources =
      %{
        l_dynamic: [:cpu],
        r_dynamic: [],
        static: TOPHelper.Resources.random_static(),
        objective: TOPHelper.Resources.objective(cpu: 500)
      }

    meta = %{meta| src_file_id: src_file_id}

    meta =
      if action == :edit do
        %{meta| tgt_log_id: meta.tgt_log_id || LogHelper.id()}
      else
        meta
      end

    {process_type, data, meta, resources}
  end

  defp custom_implementations do
    [
      :bruteforce,
      :log_forge_edit,
      :log_forge_create,
      :file_download,
      :file_upload,
      :install_virus
    ]
  end
end
