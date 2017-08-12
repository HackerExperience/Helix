defmodule Helix.Software.Model.SoftwareType.LogForge do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Helix.Entity.Model.Entity
  alias Helix.Log.Model.Log
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File

  @type t :: %__MODULE__{
    target_log_id: Log.id | nil,
    target_server_id: Server.id | nil,
    entity_id: Entity.id,
    operation: String.t,
    message: String.t,
    version: pos_integer
  }

  @type create_params ::
    %{String.t => term}
    | %{
      :entity_id => Entity.idtb,
      :operation => String.t,
      :message => String.t,
      optional(:target_server_id) => Server.idtb,
      optional(:target_log_id) => Log.idtb,
      optional(atom) => any
    }

  @edit_revision_cost 10_000
  @edit_version_cost 150
  @create_version_cost 400

  @primary_key false
  embedded_schema do
    field :target_log_id, Log.ID
    field :entity_id, Entity.ID
    field :target_server_id, Server.ID

    # TODO: use atom
    field :operation, :string

    field :message, :string
    field :version, :integer
  end

  @spec create(create_params, File.modules) ::
    {:ok, t}
    | {:error, Changeset.t}
  def create(params, modules) do
    %__MODULE__{}
    |> cast(params, [:entity_id, :operation, :message])
    |> validate_required([:entity_id, :operation])
    |> validate_inclusion(:operation, ["edit", "create"])
    |> cast_modules(params, modules)
    |> format_return()
  end

  @spec edit_objective(t, Log.t, non_neg_integer) ::
    %{cpu: pos_integer}
  def edit_objective(data = %{operation: "edit"}, target_log, revision_count) do
    revision_cost = if data.entity_id == target_log.entity_id do
      factorial(revision_count) * @edit_revision_cost
    else
      factorial(revision_count + 1) * @edit_revision_cost
    end

    version_cost = data.version * @edit_version_cost

    %{cpu: revision_cost + version_cost}
  end

  @spec create_objective(t) ::
    %{cpu: pos_integer}
  def create_objective(data = %{operation: "create"}) do
    %{cpu: data.version * @create_version_cost}
  end

  @spec cast_modules(Changeset.t, create_params, File.modules) ::
    Changeset.t
  defp cast_modules(changeset, params, modules) do
    case get_change(changeset, :operation) do
      "create" ->
        changeset
        |> cast(%{version: modules.log_forger_create}, [:version])
        |> cast(params, [:target_server_id])
        |> validate_required([:target_server_id, :version])
        |> validate_number(:version, greater_than: 0)
      "edit" ->
        changeset
        |> cast(%{version: modules.log_forger_edit}, [:version])
        |> cast(params, [:target_log_id])
        |> validate_required([:target_log_id, :version])
        |> validate_number(:version, greater_than: 0)
      _ ->
        # Changeset should already be invalid
        changeset
    end
  end

  @spec format_return(Changeset.t) ::
    {:ok, t}
    | {:error, Changeset.t}
  defp format_return(changeset = %{valid?: true}),
    do: {:ok, apply_changes(changeset)}
  defp format_return(changeset),
    do: {:error, changeset}

  @spec factorial(non_neg_integer) ::
    non_neg_integer
  defp factorial(n),
    do: Enum.reduce(1..n, &(&1 * &2))

  defimpl Helix.Process.Model.Process.ProcessType do

    alias Ecto.Changeset
    alias Helix.Software.Model.SoftwareType.LogForge.Edit.ConclusionEvent,
      as: EditConclusion
    alias Helix.Software.Model.SoftwareType.LogForge.Create.ConclusionEvent,
      as: CreateConclusion

    @ram_base_factor 5
    @ram_sqrt_factor 50

    def dynamic_resources(_),
      do: [:cpu]

    def minimum(%{version: v}),
      do: %{
        paused: %{
          ram: v * @ram_base_factor + trunc(:math.sqrt(v) * @ram_sqrt_factor)
        },
        running: %{
          ram: v * @ram_base_factor + trunc(:math.sqrt(v) * @ram_sqrt_factor)
        }
    }

    def kill(_, process, _),
      do: {%{Changeset.change(process)| action: :delete}, []}

    def state_change(data, process, _, :complete) do
      process = %{Changeset.change(process)| action: :delete}

      event = conclusion_event(data)

      {process, [event]}
    end

    def state_change(_, process, _, _),
      do: {process, []}

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)

    defp conclusion_event(data = %{operation: "edit"}) do
      %EditConclusion{
        target_log_id: data.target_log_id,
        entity_id: data.entity_id,
        message: data.message,
        version: data.version
      }
    end

    defp conclusion_event(data = %{operation: "create"}) do
      %CreateConclusion{
        entity_id: data.entity_id,
        target_server_id: data.target_server_id,
        message: data.message,
        version: data.version
      }
    end
  end

  defimpl Helix.Process.API.View.Process do

    alias Helix.Entity.Model.Entity
    alias Helix.Log.Model.Log
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
        :network_id => Network.id | nil,
        :connection_id => Connection.id | nil,
        :process_type => term,
        optional(:target_log_id) => Log.id,
        optional(:state) => State.state,
        optional(:objective) => Resources.t,
        optional(:processed) => Resources.t,
        optional(:allocated) => Resources.t,
        optional(:priority) => 0..5,
        optional(:creation_time) => DateTime.t,
        optional(:version) => non_neg_integer
      }
    def render(data, process = %{gateway_id: server}, server, _),
      do: do_render(data, process, :local)
    def render(data = %{entity_id: entity}, process, _, entity),
      do: do_render(data, process, :local)
    def render(data, process, _, _),
      do: do_render(data, process, :remote)

    defp do_render(data, process, scope) do
      base = take_data_from_process(process, scope)
      complement = take_complement_from_data(data, scope)

      Map.merge(base, complement)
    end

    defp take_complement_from_data(data = %{operation: "edit"}, :local),
      do: %{target_log_id: data.target_log_id, version: data.version}
    defp take_complement_from_data(data = %{operation: "edit"}, :remote),
      do: %{target_log_id: data.target_log_id}
    defp take_complement_from_data(data = %{operation: "create"}, :local),
      do: %{version: data.version}
    defp take_complement_from_data(%{operation: "create"}, :remote),
      do: %{}

    defp take_data_from_process(process, :remote) do
      %{
        process_id: process.process_id,
        gateway_id: process.gateway_id,
        target_server_id: process.target_server_id,
        network_id: process.network_id,
        connection_id: process.connection_id,
        process_type: process.process_type,
      }
    end

    defp take_data_from_process(process, :local) do
      %{
        process_id: process.process_id,
        gateway_id: process.gateway_id,
        target_server_id: process.target_server_id,
        network_id: process.network_id,
        connection_id: process.connection_id,
        process_type: process.process_type,
        state: process.state,
        objective: process.objective,
        processed: process.processed,
        allocated: process.allocated,
        priority: process.priority,
        creation_time: process.creation_time
      }
    end
  end
end
