defmodule Helix.Software.Model.Software.Cracker.Bruteforce do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias HELL.IPv4
  alias Helix.Network.Model.Network
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File

  @type changeset :: %Ecto.Changeset{data: %__MODULE__{}}

  @type t :: %__MODULE__{
    network_id: Network.id,
    target_server_id: Server.id,
    target_server_ip: IPv4.t,
    software_version: pos_integer
  }

  @type create_params ::
    # %{String.t => term}
    %{
      :network_id => Network.idtb,
      :target_server_id => Server.idtb,
      :target_server_ip => IPv4.t
    }

  @create_params ~w/
    network_id
    target_server_id
    target_server_ip
  /a
  @required_params ~w/
    network_id
    target_server_id
    target_server_ip
    software_version
  /a

  @primary_key false
  embedded_schema do
    field :network_id, Network.ID
    field :target_server_id, Server.ID
    field :target_server_ip, IPv4

    field :software_version, :integer
  end

  @spec create(File.t_of_type(:cracker), create_params) ::
    {:ok, t}
    | {:error, changeset}
  def create(file, params) do
    version = %{software_version: file.modules.overflow.version}

    %__MODULE__{}
    |> cast(params, @create_params)
    |> cast(version, [:software_version])
    |> validate_required(@required_params)
    |> validate_number(:software_version, greater_than: 0)
    |> format_return()
  end

  @spec objective(t, non_neg_integer) ::
    %{cpu: pos_integer}
  def objective(%__MODULE__{software_version: version}, firewall_version),
    do: %{cpu: cpu_cost(version, firewall_version)}

  @spec cpu_cost(non_neg_integer, non_neg_integer) ::
    pos_integer
  defp cpu_cost(software_version, firewall_version) do
    factor = max(firewall_version - software_version, 0)
    50_000 + factor * 125
  end

  @spec format_return(changeset) ::
    {:ok, t}
    | {:error, changeset}
  defp format_return(changeset = %Ecto.Changeset{valid?: true}),
    do: {:ok, apply_changes(changeset)}
  defp format_return(changeset),
    do: {:error, changeset}

  defimpl Helix.Process.Model.Process.ProcessType do
    @moduledoc false

    alias Ecto.Changeset
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Software.Model.Software.Cracker.Bruteforce
    alias Helix.Software.Event.Cracker.Bruteforce.Processed,
      as: BruteforceProcessedEvent

    @ram_base 3

    def dynamic_resources(_),
      do: [:cpu]

    def minimum(%{software_version: v}) do
      %{
        paused: %{ram: v * @ram_base},
        running: %{ram: v * @ram_base}
      }
    end

    def kill(_, process, _),
      do: {%{Changeset.change(process)| action: :delete}, []}

    def state_change(data, process, _, :complete) do
      process =
        process
        |> Ecto.Changeset.change()
        |> Map.put(:action, :delete)

      event =
        BruteforceProcessedEvent.new(Changeset.apply_changes(process), data)

      {process, [event]}
    end

    def state_change(_, process, _, _),
      do: {process, []}

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)

    def after_read_hook(data) do
      %Bruteforce{
        software_version: data.software_version,
        network_id: Network.ID.cast!(data.network_id),
        target_server_ip: data.target_server_ip,
        target_server_id: Server.ID.cast!(data.target_server_id)
      }
    end
  end

  defimpl Helix.Process.Public.View.ProcessViewable do
    @moduledoc false

    alias Helix.Process.Model.Process
    alias Helix.Process.Public.View.Process, as: ProcessView
    alias Helix.Process.Public.View.Process.Helper, as: ProcessViewHelper

    @type data :: %{}

    def get_scope(data, process, server, entity),
      do: ProcessViewHelper.get_default_scope(data, process, server, entity)

    @spec render(term, Process.t, ProcessView.scopes) ::
      {ProcessView.full_process | ProcessView.partial_process, data}
    def render(_, process, scope) do
      rendered_process = take_data_from_process(process, scope)

      {rendered_process, %{}}
    end

    defp take_data_from_process(process, scope),
      do: ProcessViewHelper.default_process_render(process, scope)
  end
end

# TODO: Merge
defmodule Helix.Software.Model.Software.Cracker.Overflow do

  use Ecto.Schema

  import Ecto.Changeset

  alias Helix.Network.Model.Connection
  alias Helix.Process.Model.Process
  alias Helix.Software.Model.File
  alias Helix.Software.Event.Cracker.Overflow.Processed,
    as: OverflowProcessedEvent

  @type changeset :: %Ecto.Changeset{data: %__MODULE__{}}

  @type t :: %__MODULE__{
    target_process_id: Process.id | nil,
    target_connection_id: Connection.id | nil,
    software_version: pos_integer
  }

  @type create_params ::
    %{
      target_process_id: Process.idtb | nil,
      target_connection_id: Connection.idtb | nil
    }

  @create_params ~w/target_process_id target_connection_id/a
  @required_params ~w/target_process_id target_connection_id/a

  @primary_key false
  embedded_schema do
    field :target_process_id, Process.ID
    field :target_connection_id, Connection.ID
    field :software_version, :integer
  end

  @spec create(File.t_of_type(:cracker), create_params) ::
    {:ok, t}
    | {:error, changeset}
  def create(file, params) do
    version = %{software_version: file.modules.bruteforce.version}

    %__MODULE__{}
    |> cast(params, @create_params)
    |> cast(version, [:software_version])
    |> validate_required(@required_params)
    |> validate_number(:software_version, greater_than: 0)
    |> format_return()
  end

  @spec format_return(changeset) ::
    {:ok, t}
    | {:error, changeset}
  defp format_return(changeset = %Ecto.Changeset{valid?: true}),
    do: {:ok, apply_changes(changeset)}
  defp format_return(changeset),
    do: {:error, changeset}

  defimpl Helix.Process.Model.Process.ProcessType do

    import Helix.Process

    alias Helix.Network.Model.Connection
    alias Helix.Process.Model.Process

    @moduledoc false

    @ram_base 3

    def dynamic_resources(_),
      do: [:cpu]

    def minimum(%{software_version: v}) do
      %{
        paused: %{ram: v * @ram_base},
        running: %{ram: v * @ram_base}
      }
    end

    def kill(_, process, _),
      do: {delete(process), []}

    def state_change(data, process, _, :complete) do
      unchange(process)

      event = OverflowProcessedEvent.new(process, data)

      {delete(process), [event]}
    end

    def state_change(_, process, _, _),
      do: {process, []}

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)

    def after_read_hook(data),
      do: data
  end
end
