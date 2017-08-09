defmodule Helix.Software.Model.SoftwareType.LogForge do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Helix.Entity.Model.Entity
  alias Helix.Log.Model.Log
  alias Helix.Software.Model.File

  @type t :: %__MODULE__{
    target_log_id: Log.id,
    entity_id: Entity.id,
    message: String.t,
    version: pos_integer
  }

  @type create_params ::
    %{String.t => term}
    | %{
      :target_log_id => Log.idtb,
      :entity_id => Entity.idtb,
      :message => String.t,
      optional(atom) => any
    }

  @primary_key false
  embedded_schema do
    field :target_log_id, Log.ID
    field :entity_id, Entity.ID

    field :message, :string
    field :version, :integer
  end

  @spec create(create_params, File.modules) ::
    {:ok, t}
    | {:error, Changeset.t}
  def create(params, modules) do
    %__MODULE__{}
    |> cast(params, [:target_log_id, :message, :entity_id])
    |> validate_required([:target_log_id, :entity_id])
    |> cast_modules(modules)
    |> format_return()
  end

  @spec objective(t, Log.t, non_neg_integer) ::
    %{cpu: pos_integer}
  def objective(process_data, target_log, revision_count) do
    cost_factor =
      (process_data.entity_id == target_log.entity_id)
      && revision_count
      || (revision_count + 1)

    %{
      cpu: factorial(cost_factor) * 12_500
    }
  end

  @spec cast_modules(Changeset.t, File.modules) ::
    Changeset.t
  defp cast_modules(changeset, %{log_forger_edit: version}) do
    changeset
    |> cast(%{version: version}, [:version])
    |> validate_number(:version, greater_than: 0)
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
    alias Helix.Software.Model.SoftwareType.LogForge.ProcessConclusionEvent

    @ram_base_factor 10

    def dynamic_resources(_),
      do: [:cpu]

    def minimum(%{version: v}),
      do: %{
        paused: %{
          ram: v * @ram_base_factor
        },
        running: %{
          ram: v * @ram_base_factor
        }
    }

    def kill(_, process, _),
      do: {%{Changeset.change(process)| action: :delete}, []}

    def state_change(data, process, _, :complete) do
      process = %{Changeset.change(process)| action: :delete}

      event = %ProcessConclusionEvent{
        target_log_id: data.target_log_id,
        version: data.version,
        message: data.message,
        entity_id: data.entity_id
      }

      {process, [event]}
    end

    def state_change(_, process, _, _),
      do: {process, []}

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)
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
        :target_log_id => Log.id,
        optional(:state) => State.state,
        optional(:objective) => Resources.t,
        optional(:processed) => Resources.t,
        optional(:allocated) => Resources.t,
        optional(:priority) => 0..5,
        optional(:creation_time) => DateTime.t,
        optional(:version) => non_neg_integer
      }
    def render(data, process = %{gateway_id: server}, server, _),
      do: render_local(data, process)
    def render(data = %{entity_id: entity}, process, _, entity),
      do: render_local(data, process)
    def render(data, process, _, _),
      do: render_remote(data, process)

    defp render_local(data, process) do
      base = take_data_from_process(process, :local)
      complement = %{
        target_log_id: data.target_log_id,
        version: data.version
      }

      Map.merge(base, complement)
    end

    defp render_remote(data, process) do
      base = take_data_from_process(process, :remote)
      complement = %{
        target_log_id: data.target_log_id
      }

      Map.merge(base, complement)
    end

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
