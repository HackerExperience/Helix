defmodule Helix.Process.Model.Process do

  use Ecto.Schema
  use HELL.ID, field: :process_id, meta: [0x0021]

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Process.Model.Process.Limitations
  alias Helix.Process.Model.Process.MapServerToProcess
  alias Helix.Process.Model.Process.NaiveStruct
  alias Helix.Process.Model.Process.Resources
  alias Helix.Process.Model.Processable
  alias Helix.Process.Model.Process.State

  @type type :: String.t

  @type t :: %__MODULE__{
    process_id: id,
    gateway_id: Server.id,
    source_entity_id: Entity.id,
    target_server_id: Server.id,
    file_id: File.id | nil,
    network_id: Network.id | nil,
    connection_id: Connection.id | nil,
    process_data: Processable.t,
    process_type: type,
    state: State.state,
    limitations: Limitations.t,
    objective: Resources.t,
    processed: Resources.t,
    allocated: Resources.t,
    priority: 0..5,
    minimum: map,
    creation_time: DateTime.t,
    updated_time: DateTime.t,
    estimated_time: DateTime.t | nil
  }

  @type process :: %__MODULE__{} | %Ecto.Changeset{data: %__MODULE__{}}

  @type create_params :: %{
    :gateway_id => Server.idtb,
    :source_entity_id => Entity.idtb,
    :target_server_id => Server.idtb,
    :process_data => Processable.t,
    :process_type => String.t,
    optional(:file_id) => File.idtb,
    optional(:network_id) => Network.idtb,
    optional(:connection_id) => Connection.idtb,
    optional(:objective) => map
  }

  @type update_params :: %{
    optional(:state) => State.state,
    optional(:priority) => 0..5,
    optional(:creation_time) => DateTime.t,
    optional(:updated_time) => DateTime.t,
    optional(:estimated_time) => DateTime.t | nil,
    optional(:limitations) => map,
    optional(:objective) => map,
    optional(:processed) => map,
    optional(:allocated) => map,
    optional(:minimum) => map,
    optional(:process_data) => Processable.t
  }

  @creation_fields ~w/
    process_data
    process_type
    gateway_id
    source_entity_id
    target_server_id
    file_id
    network_id
    connection_id/a
  @update_fields ~w/state priority updated_time estimated_time minimum/a

  @required_fields ~w/
    gateway_id
    target_server_id
    process_data
    process_type/a

  schema "processes" do
    field :process_id, ID,
      primary_key: true

    # The gateway that started the process
    field :gateway_id, Server.ID
    # The entity that started the process
    field :source_entity_id, Entity.ID
    # The server where the target object of this process action is
    field :target_server_id, Server.ID
    # Which file (if any) contains the "executable" of this process
    field :file_id, File.ID
    # Which network is this process bound to (if any)
    field :network_id, Network.ID
    # Which connection is the transport method for this process (if any).
    # Obviously if the connection is closed, the process will be killed. In the
    # future it might make sense to have processes that might survive after a
    # connection shutdown but right now, it's a kill
    field :connection_id, Connection.ID

    # Data that is used by the specific implementation of the process
    # side-effects
    field :process_data, NaiveStruct

    # The type of process that defines this process behaviour.
    # This field might sound redundant when `:process_data` is a struct that
    # might allow us to infer the type of process, but this field is included to
    # allow filtering by process_type (and even blocking more than one process
    # of certain process_type from running on a server) from the db
    field :process_type, :string

    # Which state in the process FSM the process is currently on
    field :state, State,
      default: :running
    # What is the process priority on the Table of Processes (only affects
    # dynamic allocation)
    field :priority, :integer,
      default: 3

    embeds_one :objective, Resources,
      on_replace: :delete
    embeds_one :processed, Resources,
      on_replace: :delete
    embeds_one :allocated, Resources,
      on_replace: :delete
    embeds_one :limitations, Limitations,
      on_replace: :delete

    # The minimum amount of resources this process requires (aka the static
    # amount of resources this process uses)
    field :minimum, :map,
      default: %{},
      virtual: true

    field :creation_time, :utc_datetime
    field :updated_time, :utc_datetime
    field :estimated_time, :utc_datetime,
      virtual: true

    # Pretend this doesn't exists. This is included on the vschema solely to
    # ensure with ease that those entries will be inserted in the same
    # transaction but only after the process is inserted
    has_many :server_to_process_map, MapServerToProcess,
      foreign_key: :process_id,
      references: :process_id
  end


  defmodule Query do
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Software.Model.File
    alias Helix.Network.Model.Connection
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Process.Model.Process
    alias Helix.Process.Model.Process.MapServerToProcess
    alias Helix.Process.Model.Process.State

    @spec by_id(Queryable.t, Process.idtb) ::
      Queryable.t
    def by_id(query \\ Process, id),
      do: where(query, [p], p.process_id == ^id)
  end
end
