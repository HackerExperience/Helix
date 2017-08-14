defmodule Helix.Software.Model.SoftwareType.Cracker do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File

  @type t :: %__MODULE__{
    entity_id: Entity.id,
    network_id: Network.id,
    target_server_id: Server.id,
    target_server_ip: IPv4.t,
    server_type: String.t,
    software_version: pos_integer,
    firewall_version: non_neg_integer
  }

  @type create_params ::
    %{String.t => term}
    | %{
      :entity_id => Entity.idtb,
      :network_id => Network.idtb,
      :target_server_id => Server.idtb,
      :target_server_ip => IPv4.t,
      :server_type => String.t,
      optional(:firewall_version) => non_neg_integer
    }

  @create_params ~w/
    entity_id
    network_id
    target_server_id
    target_server_ip
    server_type
    firewall_version
  /a
  @required_params ~w/
    entity_id
    network_id
    target_server_id
    target_server_ip
    server_type
    software_version
  /a

  @primary_key false
  embedded_schema do
    field :entity_id, Entity.ID

    field :network_id, Network.ID
    field :target_server_id, Server.ID
    field :target_server_ip, IPv4
    field :server_type, :string

    field :software_version, :integer
    field :firewall_version, :integer,
      default: 0
  end

  @spec create(File.t_of_type(:cracker), create_params) ::
    {:ok, t}
    | {:error, Changeset.t}
  def create(file, params) do
    version = %{software_version: file.file_modules.cracker_password}

    %__MODULE__{}
    |> cast(params, @create_params)
    |> cast(version, [:software_version])
    |> validate_required(@required_params)
    |> validate_number(:software_version, greater_than: 0)
    |> validate_number(:firewall_version, greater_than_or_equal_to: 0)
    |> format_return()
  end

  @spec objective(t) ::
    %{cpu: pos_integer}
  def objective(%__MODULE__{software_version: s, firewall_version: f}),
    do: %{cpu: cpu_cost(s, f)}

  def firewall_version(cracker, version) do
    cracker
    |> cast(%{firewall_version: version}, [:firewall_version])
    |> validate_required([:firewall_version])
    |> validate_number(:firewall_version, greater_than_or_equal_to: 0)
    |> format_return()
  end

  @spec cpu_cost(non_neg_integer, non_neg_integer) ::
    pos_integer
  defp cpu_cost(software_version, firewall_version) do
    factor = max(firewall_version - software_version, 0)
    50_000 + factor * 125
  end

  @spec format_return(Changeset.t) ::
    {:ok, t}
    | {:error, Changeset.t}
  defp format_return(changeset = %{valid?: true}),
    do: {:ok, apply_changes(changeset)}
  defp format_return(changeset),
    do: {:error, changeset}

  defimpl Helix.Process.Model.Process.ProcessType do
    @moduledoc false

    alias Helix.Software.Model.SoftwareType.Cracker.ProcessConclusionEvent

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
      do: {%{Ecto.Changeset.change(process)| action: :delete}, []}

    def state_change(data, process, _, :complete) do
      process =
        process
        |> Ecto.Changeset.change()
        |> Map.put(:action, :delete)

      event = %ProcessConclusionEvent{
        entity_id: data.entity_id,
        network_id: data.network_id,
        server_id: data.target_server_id,
        server_ip: data.target_server_ip,
        server_type: data.server_type
      }

      {process, [event]}
    end

    def state_change(_, process, _, _),
      do: {process, []}

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)
  end

  defimpl Helix.Process.API.View.Process do
    @moduledoc false

    alias Helix.Entity.Model.Entity
    alias Helix.Network.Model.Connection
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Process.Model.Process
    alias Helix.Process.Model.Process.Resources
    alias Helix.Process.Model.Process.State

    @spec render(map, Process.t, Server.id, Entity.id) ::
      %{
        :process_id => Process.id,
        :gateway_id => Server.id,
        :target_server_id => Server.id,
        :network_id => Network.id,
        :connection_id => Connection.id,
        :process_type => term,
        optional(:state) => State.state,
        optional(:allocated) => Resources.t,
        optional(:priority) => 0..5,
        optional(:creation_time) => DateTime.t,
        optional(:software_version) => non_neg_integer,
        optional(:target_server_ip) => HELL.IPv4.t
      }
    def render(data, process = %{gateway_id: server}, server, _) do
      base = take_data_from_process(process)
      complement = %{
        software_version: data.software_version,
        target_server_ip: data.target_server_ip
      }

      Map.merge(base, complement)
    end

    def render(data = %{entity_id: entity}, process, _, entity) do
      base = take_data_from_process(process)
      complement = %{
        software_version: data.software_version,
        target_server_ip: data.target_server_ip
      }

      Map.merge(base, complement)
    end

    def render(_, process, _, _) do
      process
      |> take_data_from_process()
      |> Map.drop([:state, :allocated, :priority, :creation_time])
    end

    defp take_data_from_process(process) do
      %{
        process_id: process.process_id,
        gateway_id: process.gateway_id,
        target_server_id: process.target_server_id,
        network_id: process.network_id,
        connection_id: process.connection_id,
        process_type: process.process_type,
        state: process.state,
        allocated: process.allocated,
        priority: process.priority,
        creation_time: process.creation_time
      }
    end
  end
end
