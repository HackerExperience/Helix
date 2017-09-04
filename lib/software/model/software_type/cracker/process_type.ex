defmodule Helix.Software.Model.Software.Cracker.Bruteforce do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File

  @type changeset :: %Ecto.Changeset{data: %__MODULE__{}}

  @type t :: %__MODULE__{
    source_entity_id: Entity.id,
    network_id: Network.id,
    target_server_id: Server.id,
    target_server_ip: IPv4.t,
    software_version: pos_integer
  }

  @type create_params ::
    %{String.t => term}
    | %{
      :source_entity_id => Entity.idtb,
      :network_id => Network.idtb,
      :target_server_id => Server.idtb,
      :target_server_ip => IPv4.t
    }

  @create_params ~w/
    source_entity_id
    network_id
    target_server_id
    target_server_ip
  /a
  @required_params ~w/
    source_entity_id
    network_id
    target_server_id
    target_server_ip
    software_version
  /a

  @primary_key false
  embedded_schema do
    field :source_entity_id, Entity.ID

    field :network_id, Network.ID
    field :target_server_id, Server.ID
    field :target_server_ip, IPv4

    field :software_version, :integer
  end

  @spec create(File.t_of_type(:cracker), create_params) ::
    {:ok, t}
    | {:error, changeset}
  def create(file, params) do
    version = %{software_version: file.file_modules.overflow}

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

    alias Helix.Software.Model.Software.Cracker.Bruteforce.ConclusionEvent,
      as: CrackerBruteforceConclusionEvent

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

      event = %CrackerBruteforceConclusionEvent{
        source_entity_id: Entity.ID.cast!(data.source_entity_id),
        network_id: Network.ID.cast!(data.network_id),
        target_server_id: Server.ID.cast!(data.target_server_id),
        target_server_ip: data.target_server_ip
      }

      {process, [event]}
    end

    def state_change(_, process, _, _),
      do: {process, []}

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)
  end

  defimpl Helix.Process.Public.View.ProcessViewable do
    @moduledoc false

    alias HELL.IPv4
    alias Helix.Entity.Model.Entity
    alias Helix.Network.Model.Connection
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Process.Model.Process
    alias Helix.Process.Public.View.Process, as: ProcessView
    alias Helix.Process.Public.View.Process.Helper, as: ProcessViewHelper

    @type data ::
      %{
        :software_version => non_neg_integer,
        :target_server_ip => IPv4.t
      }

    @spec render(term, Process.t, Server.id, Entity.id) ::
      {ProcessView.local_process | ProcessView.remote_process, data}
    def render(data, process = %{gateway_id: server}, server, _),
      do: do_render(data, process, :local)
    def render(data = %{source_entity_id: entity}, process, _, entity),
      do: do_render(data, process, :local)
    def render(data, process, _, _),
      do: do_render(data, process, :remote)

    defp do_render(data, process, scope) do
      rendered_process = take_data_from_process(process, scope)
      rendered_data = take_complement_from_data(data, scope)

      {rendered_process, rendered_data}
    end

    defp take_complement_from_data(data, _) do
      %{
        software_version: data.software_version,
        target_server_ip: data.target_server_ip
      }
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
  alias Helix.Software.Model.Software.Cracker.Overflow.ConclusionEvent,
    as: OverflowConclusionEvent

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
    version = %{software_version: file.file_modules.bruteforce}

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

    alias Helix.Network.Model.Connection
    alias Helix.Process.Model.Process
    alias Helix.Server.Model.Server

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
      do: {%{Ecto.Changeset.change(process)| action: :delete}, []}

    def state_change(data, process, _, :complete) do
      process =
        process
        |> Ecto.Changeset.change()
        |> Map.put(:action, :delete)

      event = %OverflowConclusionEvent{
        gateway_id: Server.ID.cast!(process.data.gateway_id),
        target_process_id: Process.ID.cast!(data.target_process_id),
        target_connection_id: Connection.ID.cast!(data.target_connection_id)
      }

      {process, [event]}
    end

    def state_change(_, process, _, _),
      do: {process, []}

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)
  end
end
