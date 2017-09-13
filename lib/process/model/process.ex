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
  alias Helix.Process.Model.Process.ProcessType
  alias Helix.Process.Model.Process.State

  @type t :: %__MODULE__{
    process_id: id,
    gateway_id: Server.id,
    source_entity_id: Entity.id,
    target_server_id: Server.id,
    file_id: File.id | nil,
    network_id: Network.id | nil,
    connection_id: Connection.id | nil,
    process_data: ProcessType.t,
    process_type: String.t,
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
    :process_data => ProcessType.t,
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
    optional(:process_data) => ProcessType.t
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

  @spec create_changeset(create_params) ::
    Changeset.t
  def create_changeset(params) do
    now = DateTime.utc_now()

    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_change(:creation_time, now)
    |> put_change(:updated_time, now)
    |> validate_change(:process_data, fn :process_data, value ->
      # Only accepts as input structs that implement protocol ProcessType to
      # ensure that they will be properly processed
      if ProcessType.impl_for(value),
        do: [],
        else: [process_data: "invalid value"]
    end)
    |> put_defaults()
    |> changeset(params)
    |> server_to_process_map()
    |> Map.put(:action, :insert)
  end

  @spec put_defaults(Changeset.t) ::
    Changeset.t
  defp put_defaults(changeset) do
    cs =
      get_change(changeset, :limitations)
      && changeset
      || put_embed(changeset, :limitations, %{})

    cs
    |> put_embed(:processed, %{})
    |> put_embed(:allocated, %{})
  end

  @spec update_changeset(process, update_params) ::
    Changeset.t
  def update_changeset(process, params) do
    process
    |> cast(params, @update_fields)
    |> cast_embed(:processed)
    |> cast_embed(:allocated)
    |> cast_embed(:limitations)
    |> validate_process_data(params)
    |> changeset(params)
    |> Map.put(:action, :update)
  end

  defp validate_process_data(changeset, params) do
    process_data = get_field(changeset, :process_data)

    changeset
    |> cast(params, [:process_data])
    |> validate_change(:process_data, fn :process_data, new_data ->
      if process_data.__struct__ == new_data.__struct__,
        do: [],
        else: [process_data: "type changed"]
    end)
  end

  @spec changeset(process, map) ::
    Changeset.t
  @doc false
  def changeset(struct, params) do
    struct
    |> cast(params, [:updated_time])
    |> cast_embed(:objective)
    |> validate_required(@required_fields)
    |> validate_inclusion(:priority, 0..5)
  end

  @spec load_virtual_data(t) ::
    t
  @doc """
  Updates `minimum` and `estimated_time`  into the process
  """
  def load_virtual_data(process) do
    minimum = ProcessType.minimum(process.process_data)

    process
    |> estimate_conclusion()
    |> Map.put(:minimum, minimum)
  end

  @spec format(Process.t) ::
    Process.t
  @doc """
  Converts the retrieved process from the Database into TOP's internal format.

  Notably, it:
  - Adds virtual data (derived data not stored on DB).
  - Converts the ProcessType (defined at `process_data`) into Helix internal
    format, by using the `after_read_hook/1` implemented by each ProcessType
  """
  def format(process) do
    data = ProcessType.after_read_hook(process.process_data)

    process
    |> load_virtual_data()
    |> Map.replace(:process_data, data)
  end

  @spec complete?(process) :: boolean
  def complete?(process = %Ecto.Changeset{}),
    do: complete?(apply_changes(process))
  def complete?(%__MODULE__{state: state, objective: objective, processed: processed}),
    do: state == :complete or (objective && objective == processed)

  @spec kill(process, atom) ::
    {[process] | process, [struct]}
  def kill(process = %__MODULE__{}, reason),
    do: ProcessType.kill(process.process_data, process, reason)
  def kill(process = %Ecto.Changeset{}, reason),
    do: ProcessType.kill(get_change(process, :process_data), process, reason)

  @spec allocate_minimum(process) ::
    Changeset.t
  def allocate_minimum(process) do
    process = change(process)

    minimum =
      process
      |> get_field(:minimum)
      |> Map.get(get_field(process, :state), %{})

    update_changeset(process, %{allocated: minimum})
  end

  @spec allocate(process, Resources.resourceable) ::
    Changeset.t
  def allocate(process, amount) do
    cs = change(process)

    # The amount we want to allocate
    allocable =
      cs
      |> get_field(:allocated)
      |> Resources.sum(amount)

    allocated =
      cs
      |> get_field(:limitations)
      |> Limitations.to_list()
      |> Enum.reduce(allocable, fn
        {_, nil}, acc ->
          acc
        {field, value}, acc ->
          # If there is a limit to certain resource, don't allow the allocation
          # to exceed that limit
          Map.update!(acc, field, &min(&1, value))
      end)
      |> Map.from_struct()

    update_changeset(cs, %{allocated: allocated})
  end

  @spec allocation_shares(process) ::
    non_neg_integer
  def allocation_shares(process) do
    case process do
      %__MODULE__{state: state, priority: priority}
      when state in [:standby, :running] ->
        can_allocate?(process)
        && priority
        || 0
      %__MODULE__{} ->
        0
      %Ecto.Changeset{} ->
        process
        |> apply_changes()
        |> allocation_shares()
    end
  end

  @spec pause(process) ::
    {[t | Ecto.Changeset.t] | t | Ecto.Changeset.t, [struct]}
  def pause(process) do
    changeset = change(process)
    state = get_field(changeset, :state)

    if :paused == state do
      {changeset, []}
    else
      changeset =
        changeset
        |> calculate_work(DateTime.utc_now())
        |> update_changeset(%{state: :paused, estimated_time: nil})
        |> allocate_minimum()

      changeset
      |> get_field(:process_data)
      |> ProcessType.state_change(changeset, state, :paused)
    end
  end

  @spec resume(process) ::
    {[t | Ecto.Changeset.t] | t | Ecto.Changeset.t, [struct]}
  def resume(process) do
    changeset = change(process)
    state = get_field(changeset, :state)

    if :paused == state do
      # FIXME: state can be "standby" on some cases
      changeset =
        changeset
        |> update_changeset(%{
          state: :running,
          updated_time: DateTime.utc_now()})
        |> allocate_minimum()
        |> estimate_conclusion()

      changeset
      |> get_field(:process_data)
      |> ProcessType.state_change(changeset, state, :running)
    else
      changeset
    end
  end

  @spec calculate_work(elem, DateTime.t) ::
    elem when elem: process
  def calculate_work(p = %__MODULE__{}, now) do
    p
    |> change()
    |> calculate_work(now)
    |> apply_changes()
  end

  def calculate_work(process, now) do
    if :running == get_field(process, :state) do
      diff =
        process
        |> get_field(:updated_time)
        |> diff_in_seconds(now)

      processed = calculate_processed(process, diff)

      update_changeset(process, %{updated_time: now, processed: processed})
    else
      process
    end
  end

  @spec estimate_conclusion(elem) ::
    elem when elem: process
  def estimate_conclusion(process = %__MODULE__{}) do
    process
    |> change()
    |> estimate_conclusion()
    |> apply_changes()
  end

  def estimate_conclusion(process) do
    objective = get_field(process, :objective)
    processed = get_field(process, :processed)
    allocated = get_field(process, :allocated)

    conclusion =
      if objective do
        ttl =
          objective
          |> Resources.sub(processed)
          |> Resources.div(allocated)
          |> Resources.to_list()
          # Returns a list of "seconds to fulfill resource"
          |> Enum.filter(fn {_, x} -> x != 0 end)
          |> Enum.map(&elem(&1, 1))
          |> Enum.reduce(0, &max/2)

        case ttl do
          x when not x in [0, nil] ->
            process
            |> get_field(:updated_time)
            |> Timex.shift(seconds: x)
          _ ->
            # Exceptional case when all resources are "0" (ie: nothing to do)
            # Also includes the case of when a certain resource will never be
            # completed
            nil
        end
      else
        nil
      end

    update_changeset(process, %{estimated_time: conclusion})
  end

  @spec seconds_to_change(process) ::
    non_neg_integer
    | :infinity
  @doc """
  How many seconds until the `process` change state or frees some resource from
  completing part of it's objective
  """
  def seconds_to_change(p = %Changeset{}),
    do: seconds_to_change(apply_changes(p))
  def seconds_to_change(%{objective: nil}),
    do: :infinity
  def seconds_to_change(process) do
    process.objective
    |> Resources.sub(process.processed)
    |> Resources.div(process.allocated)
    |> Resources.to_list()
    |> Keyword.values()
    |> Enum.filter(&(is_integer(&1) and &1 > 0))
    |> Enum.reduce(:infinity, &min/2) # Note that atom > int
  end

  @spec can_allocate?(process, res | [res]) ::
    boolean when res: (:cpu | :ram | :dlk | :ulk)
  @doc """
  Checks if the `process` can allocate any of the specified `resources`
  """
  def can_allocate?(process, resources  \\ [:cpu, :ram, :dlk, :ulk]) do
    resources = List.wrap(resources)
    Enum.any?(can_allocate(process), &(&1 in resources))
  end

  # TODO: rename this
  @spec can_allocate(process) ::
    [:cpu | :ram | :dlk | :ulk]
  @doc """
  Returns a list with all resources that the `process` can allocate
  """
  def can_allocate(process = %Changeset{}),
    do: can_allocate(apply_changes(process))
  def can_allocate(process = %__MODULE__{}) do
    dynamic_resources = ProcessType.dynamic_resources(process.process_data)

    allowed =
      case process.objective do
        nil ->
          []
        objective ->
          remaining = Resources.sub(objective, process.processed)

          Enum.filter(dynamic_resources, fn resource ->
            remaining = Map.get(remaining, resource)
            is_integer(remaining) and remaining > 0
          end)
      end

    dynamic_resources
    |> Enum.filter(fn resource ->
      # Note that this is `nil` unless a value is specified.
      # Also note that nil is greater than any integer :)
      limitations = Map.get(process.limitations, resource)
      allocated = Map.get(process.allocated, resource)

      resource in allowed and limitations > allocated
    end)
  end

  @spec server_to_process_map(Changeset.t) ::
    Changeset.t
  defp server_to_process_map(changeset) do
    process_type = get_field(changeset, :process_type)

    params1 = %{
      server_id: get_field(changeset, :gateway_id),
      process_type: process_type
    }
    params2 = %{
      server_id: get_field(changeset, :target_server_id),
      process_type: process_type
    }

    # Should both records be identical, dedup will remove one of them
    records = Enum.dedup([params1, params2])

    put_assoc(changeset, :server_to_process_map, records)
  end

  @spec diff_in_seconds(DateTime.t, DateTime.t) ::
    non_neg_integer
    | nil
  # Returns the difference in seconds from `start` to `finish`.
  # This assumes that both the inputs are using UTC.
  defp diff_in_seconds(%DateTime{}, nil),
    do: nil
  defp diff_in_seconds(start = %DateTime{}, finish = %DateTime{}),
    do: Timex.diff(finish, start, :seconds)

  @spec calculate_processed(process, non_neg_integer) ::
    Resources.t
  # Returns the value of resources processed by `process` after adding the
  # amount processed in `seconds_passed`
  defp calculate_processed(process, seconds_passed) do
    cs = change(process)

    diff =
      cs
      |> get_field(:allocated)
      |> Resources.mul(seconds_passed)

    cs
    |> get_field(:processed)
    |> Resources.sum(diff)
    |> Resources.min(get_field(cs, :objective))
    |> Map.from_struct()
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

    @spec from_type_list(Queryable.t, [String.t]) ::
      Queryable.t
    def from_type_list(query \\ Process, type_list),
      do: where(query, [p], p.process_type in ^type_list)

    @spec from_state_list(Queryable.t, [State.state]) ::
      Queryable.t
    def from_state_list(query \\ Process, state_list),
      do: where(query, [p], p.state in ^state_list)

    @spec by_gateway(Queryable.t, Server.idtb) ::
      Queryable.t
    def by_gateway(query \\ Process, id),
      do: where(query, [p], p.gateway_id == ^id)

    @spec by_target(Queryable.t, Server.idtb) ::
      Queryable.t
    def by_target(query \\ Process, id),
      do: where(query, [p], p.target_server_id == ^id)

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
    def by_type(query \\ Process, process_type),
      do: where(query, [p], p.process_type == ^process_type)

    @spec by_state(Queryable.t, State.state) ::
      Queryable.t
    def by_state(query \\ Process, state),
      do: where(query, [p], p.state == ^state)

    @spec not_targeting_gateway(Queryable.t) ::
      Queryable.t
    def not_targeting_gateway(query \\ Process),
      do: where(query, [p], p.gateway_id != p.target_server_id)

    @spec related_to_server(Queryable.t, Server.idtb) ::
      Queryable.t
    @doc """
    Filter processes that are running on `server_id` or affect it
    """
    def related_to_server(query \\ Process, id) do
      query
      |> join(
        :inner,
        [p],
        m in MapServerToProcess,
        m.process_id == p.process_id)
      |> where([p, ..., m], m.server_id == ^id)
    end
  end
end
