defmodule Helix.Process.Model.Process do

  use Ecto.Schema
  use HELL.ID, field: :process_id, meta: [0x0021]

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.Constant
  alias HELL.MapUtils
  alias HELL.NaiveStruct
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Process.Model.Processable
  alias __MODULE__, as: Process

  @type type :: String.t

  @type t :: term
  # @type t :: %__MODULE__{
  #   process_id: id,
  #   gateway_id: Server.id,
  #   source_entity_id: Entity.id,
  #   target_server_id: Server.id,
  #   file_id: File.id | nil,
  #   network_id: Network.id | nil,
  #   connection_id: Connection.id | nil,
  #   process_data: Processable.t,
  #   process_type: type,
  #   state: State.state,
  #   limitations: Limitations.t,
  #   objective: Resources.t,
  #   processed: Resources.t,
  #   allocated: Resources.t,
  #   priority: 0..5,
  #   minimum: map,
  #   creation_time: DateTime.t,
  #   updated_time: DateTime.t,
  #   estimated_time: DateTime.t | nil
  # }

  @type process :: %__MODULE__{} | %Ecto.Changeset{data: %__MODULE__{}}

  @type creation_params :: %{
    # :gateway_id => Server.idtb,
    # :source_entity_id => Entity.idtb,
    # :target_server_id => Server.idtb,
    # :process_data => Processable.t,
    # :process_type => String.t,
    # optional(:file_id) => File.idtb,
    # optional(:network_id) => Network.idtb,
    # optional(:connection_id) => Connection.idtb,
    # optional(:objective) => map
  }

  @type update_params :: %{
    # optional(:state) => State.state,
    # optional(:priority) => 0..5,
    # optional(:creation_time) => DateTime.t,
    # optional(:updated_time) => DateTime.t,
    # optional(:estimated_time) => DateTime.t | nil,
    # optional(:limitations) => map,
    # optional(:objective) => map,
    # optional(:processed) => map,
    # optional(:allocated) => map,
    # optional(:minimum) => map,
    # optional(:process_data) => Processable.t
  }

  @creation_fields [
    :gateway_id,
    :source_entity_id,
    :target_id,
    :file_id,
    :network_id,
    :connection_id,
    :data,
    :type,
    :objective,
    :static,
    :dynamic
  ]

  @required_fields [
    :gateway_id,
    :source_entity_id,
    :target_id,
    :data,
    :type,
    :objective,
    :static,
    :priority,
    :dynamic,
    :priority
  ]

  # Similar to `task_struct` on `sched.h` ;-)
  @primary_key false
  schema "processes" do
    field :process_id, ID,
      primary_key: true

    ### Identifiers

    # The gateway that started the process
    field :gateway_id, Server.ID

    # The entity that started the process
    field :source_entity_id, Entity.ID

    # The server where the target object of this process action is
    field :target_id, Server.ID

    ### Custom keys

    # Which file (if any) is the relevant target of this process
    field :file_id, File.ID

    # Which network (if any) is this process bound to
    field :network_id, Network.ID

    # Which connection (if any) is the transport method for this process
    field :connection_id, Connection.ID

    ### Helix.Process required data

    # Data used by the specific implementation for side-effects generation
    field :data, NaiveStruct

    # The process type identifier
    field :type, Constant

    # Process priority.
    field :priority, :integer,
      default: 3

    ### Resource usage information

    # Amount of resources required in order to consider the process completed.
    field :objective, :map

    # Amount of resources that this process has already processed.
    field :processed, :map

    # Amount of resources that this process has allocated to it
    field :allocated, :map

    # Limitations
    field :limit, :map

    # Date when the process was last simulated during a `TOPAction.recalque/2`
    field :last_checkpoint_time, :utc_datetime

    # Static amount of resources used by the process
    field :static, :map

    # List of dynamically allocated resources
    field :dynamic, {:array, Constant}

    ### Metadata

    # Used by the Scheduler to accurately forecast the process, taking into
    # consideration both the current allocation (`allocated`) and the next
    # allocation, as defined by the Allocator.
    field :next_allocation, :map,
      virtual: true

    # Process state (`:running`, `:stopped`). Used internally for an easier
    # abstraction over `priority` (which is used to define the process state)
    field :state, Constant,
      virtual: true

    field :creation_time, :utc_datetime

    # Estimated date of completion
    field :estimated_time, :utc_datetime,
      virtual: true
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
    |> put_defaults()
  end

  @doc """
  Converts the retrieved process from the Database into TOP's internal format.
  Notably, it:

  - Adds virtual data (derived data not stored on DB).
  - Converts the Processable (defined at `process_data`) into Helix internal
  format, by using the `after_read_hook/1` implemented by each Processable
  """
  def format(process = %Process{}) do
    formatted_data = Processable.after_read_hook(process.data)

    process
    |> load_virtual_data()
    |> format_resources()
    |> Map.replace(:data, formatted_data)
  end

  defp format_resources(process = %Process{}) do
    process
    |> format_objective()
    |> format_allocated()
    |> format_processed()
    |> format_static()
  end

  defp format_objective(p = %{objective: objective}),
    do: %{p| objective: Process.Resources.format(objective)}

  defp format_allocated(p = %{allocated: nil}),
    do: p
  defp format_allocated(p = %{allocated: allocated}),
    do: %{p| allocated: Process.Resources.format(allocated)}

  defp format_processed(p = %{processed: nil}),
    do: p
  defp format_processed(p = %{processed: processed}),
    do: %{p| processed: Process.Resources.format(processed)}

  defp format_static(p = %{static: static}) do
    static = MapUtils.atomize_keys(static)

    %{p| static: static}
  end

  defp load_virtual_data(process = %Process{}) do
    process
    |> Map.put(:state, get_state(process))
  end

  defp get_state(%{allocated: nil}),
    do: :waiting_allocation
  defp get_state(%{priority: 0}),
    do: :paused
  defp get_state(_),
    do: :running

  defp put_defaults(changeset) do
    changeset
    |> put_change(:creation_time, DateTime.utc_now())
  end

  defmodule Query do

    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Software.Model.File
    alias Helix.Network.Model.Connection
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Process.Model.Process

    @spec by_id(Queryable.t, Process.idtb) ::
      Queryable.t
    def by_id(query \\ Process, id),
      do: where(query, [p], p.process_id == ^id)

    @spec from_type_list(Queryable.t, [String.t]) ::
      Queryable.t
    def from_type_list(query \\ Process, type_list),
      do: where(query, [p], p.type in ^type_list)

    @spec by_gateway(Queryable.t, Server.idtb) ::
      Queryable.t
    def by_gateway(query \\ Process, id),
      do: where(query, [p], p.gateway_id == ^id)

    @spec by_target(Queryable.t, Server.idtb) ::
      Queryable.t
    def by_target(query \\ Process, id),
      do: where(query, [p], p.target_id == ^id)

    @spec by_file(Queryable.t, File.idtb) ::
      Queryable.t
    def by_file(query \\ Process, id),
      do: where(query, [p], p.file_id == ^id)

    @spec by_network(Queryable.t, Network.idtb) ::
      Queryable.t
    def by_network(query \\ Process, id),
      do: where(query, [p], p.network_id == ^id)

    @spec by_connection(Queryable.t, Connection.idtb) ::
      Queryable.t
    def by_connection(query \\ Process, id),
      do: where(query, [p], p.connection_id == ^id)

    @spec by_type(Queryable.t, String.t) ::
      Queryable.t
    def by_type(query \\ Process, type),
      do: where(query, [p], p.type == ^type)

    @spec by_state(Queryable.t, :running | :paused) ::
      Queryable.t
    def by_state(query, :running),
      do: where(query, [p], p.priority > 1)
    def by_state(query, :paused),
      do: where(query, [p], p.priority == 0)

    @spec not_targeting_gateway(Queryable.t) ::
      Queryable.t
    def not_targeting_gateway(query \\ Process),
      do: where(query, [p], p.gateway_id != p.target_id)
  end
end
