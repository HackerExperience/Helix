defmodule Helix.Process.Model.Process do

  use Ecto.Schema

  alias Ecto.Changeset
  alias HELL.PK
  alias Helix.Process.Model.Process.Limitations
  alias Helix.Process.Model.Process.MapServerToProcess
  alias Helix.Process.Model.Process.NaiveStruct
  alias Helix.Process.Model.Process.Resources
  alias Helix.Process.Model.Process.ProcessType
  alias Helix.Process.Model.Process.State

  import Ecto.Changeset
  import HELL.MacroHelpers

  @type t :: %__MODULE__{
    process_id: id,
    gateway_id: PK.t,
    target_server_id: PK.t,
    file_id: PK.t | nil,
    network_id: PK.t | nil,
    process_data: ProcessType.t,
    process_type: String.t,
    state: State.state,
    limitations: Limitations.t,
    objective: Resources.t,
    processed: Resources.t,
    allocated: Resources.t,
    priority: 0..5,
    minimum: %{},
    creation_time: DateTime.t,
    updated_time: DateTime.t,
    estimated_time: DateTime.t | nil
  }

  @type process :: t | %Ecto.Changeset{data: t}

  @opaque id :: PK.t

  @primary_key false
  @ecto_autogenerate {:process_id, {PK, :pk_for, [:process_process]}}
  schema "processes" do
    field :process_id, PK,
      primary_key: true

    # The gateway that started the process
    field :gateway_id, PK
    # The server where the target object of this process action is
    field :target_server_id, PK
    # Which file (if any) contains the "executable" of this process
    field :file_id, PK
    # Which network is this process bound to (if any)
    field :network_id, PK

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
      default: :standby
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

  @creation_fields ~w/
    process_data
    process_type
    gateway_id
    target_server_id
    file_id
    network_id/a
  @update_fields ~w/state priority updated_time estimated_time minimum/a

  @required_fields ~w/gateway_id target_server_id process_data process_type/a

  @spec create_changeset(%{
    :gateway_id => PK.t,
    :target_server_id => PK.t,
    :process_data => ProcessType.t,
    :process_type => String.t,
    optional(:file_id) => PK.t,
    optional(:network_id) => PK.t,
    optional(:objective) => %{}}) :: Changeset.t
  def create_changeset(params) do
    now = DateTime.utc_now()
    params =
      params
      |> Map.put(:creation_time, now)
      |> Map.put(:updated_time, now)

    %__MODULE__{}
    |> cast(params, [:creation_time| @creation_fields])
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
  end

  @spec update_changeset(
    process,
    %{
      optional(:state) => State.state,
      optional(:priority) => 0..5,
      optional(:creation_time) => DateTime.t,
      optional(:updated_time) => DateTime.t,
      optional(:estimated_time) => DateTime.t | nil,
      optional(:limitations) => %{},
      optional(:objective) => %{},
      optional(:processed) => %{},
      optional(:allocated) => %{},
      optional(:minimum) => %{}}) :: Changeset.t
  def update_changeset(process, params) do
    process
    |> cast(params, @update_fields)
    |> cast_embed(:processed)
    |> cast_embed(:allocated)
    |> cast_embed(:limitations)
    |> changeset(params)
  end

  @spec changeset(process, %{any => any}) :: Changeset.t
  @doc false
  def changeset(struct, params) do
    struct
    |> cast(params, [:updated_time])
    |> cast_embed(:objective)
    |> validate_required(@required_fields)
    |> validate_inclusion(:priority, 0..5)
  end

  @spec complete?(t) :: boolean
  def complete?(process = %Ecto.Changeset{}),
    do: complete?(apply_changes(process))
  def complete?(%__MODULE__{state: state, objective: objective, processed: processed}),
    do: state == :complete or objective == processed

  @spec handle_complete(t) :: t | nil
  def handle_complete(p) do
    # TODO: rename this to something that sounds like a real model function and
    #   not some garbage workaround
    p
  end

  @spec allocate_minimum(process) :: Changeset.t
  def allocate_minimum(process) do
    process = change(process)

    minimum =
      process
      |> get_field(:minimum)
      |> Map.get(get_field(process, :state), %{})

    put_embed(process, :allocated, minimum)
  end

  @spec allocate(process, Resources.resourceable) :: Changeset.t
  def allocate(process, amount) do
    cs = change(process)

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
          Map.update!(acc, field, &min(&1, value))
      end)

    put_embed(cs, :allocated, allocated)
  end

  @spec allocation_shares(process) :: non_neg_integer
  def allocation_shares(process) do
    case process do
      %__MODULE__{state: state, priority: priority}
      when state in [:standby, :running] ->
        if can_allocate?(process) do
          priority
        else
          0
        end
      %__MODULE__{} ->
        0
      %Ecto.Changeset{} ->
        process
        |> apply_changes()
        |> allocation_shares()
    end
  end

  @spec pause(process) :: Changeset.t
  def pause(process = %__MODULE__{}),
    do: pause(change(process))
  def pause(process) do
    if :paused == get_field(process, :state) do
      process
    else
      process
      |> calculate_work(DateTime.utc_now())
      |> update_changeset(%{state: :paused, estimated_time: nil})
      |> allocate_minimum()
    end
  end

  @spec resume(process) :: Changeset.t
  def resume(process) do
    cs = change(process)
    state = get_field(cs, :state)

    if :paused === state do
      # FIXME: state can be "standby" on some cases
      cs
      |> update_changeset(%{state: :running, updated_time: DateTime.utc_now()})
      |> allocate_minimum()
      |> estimate_conclusion()
    else
      cs
    end
  end

  @spec calculate_work(process, DateTime.t) :: Changeset.t
  def calculate_work(process, time_now) do
    cs = change(process)

    if :running === get_field(cs, :state) do
      diff = cs |> get_field(:updated_time) |> diff_in_seconds(time_now)

      process
      |> update_changeset(%{updated_time: time_now})
      |> put_embed(:processed, calculate_processed(process, diff))
    else
      cs
    end
  end

  # REVIEW: FIXME: Maybe return as a changeset because life is a disaster
  @spec estimate_conclusion(elem) :: elem when elem: process
  def estimate_conclusion(process) do
    struct = case process do
      %__MODULE__{} ->
        process
      %Ecto.Changeset{} ->
        apply_changes(process)
    end

    conclusion = if struct.objective do
      struct.objective
      |> Resources.sub(struct.processed)
      |> Resources.div(struct.allocated)
      |> Resources.to_list()
      |> Enum.filter_map(fn {_, x} -> x != 0 end, &elem(&1, 1))
      |> Enum.reduce(0, &max/2)
      |> case do
        x when not x in [0, nil] ->
          Timex.shift(struct.updated_time, seconds: x)
        _ ->
          # Exceptional case when all resources are "0" (ie: nothing to do)
          # Also includes the case of when a certain resource will never be
          # completed
          nil
      end
    end

    changeset = cast(process, %{estimated_time: conclusion}, [:estimated_time])
    case process do
      %__MODULE__{} ->
        apply_changes(changeset)
      %Ecto.Changeset{} ->
        changeset
    end
  end

  @spec seconds_to_change(t | Ecto.Changeset.t) :: non_neg_integer | nil
  @doc """
  How many seconds until the `process` change state or frees some resource from
  completing part of it's objective
  """
  def seconds_to_change(p = %Ecto.Changeset{}),
    do: seconds_to_change(apply_changes(p))
  def seconds_to_change(process) do
    process.objective
    |> Resources.sub(process.processed)
    |> Resources.div(process.allocated)
    |> Resources.to_list()
    |> Keyword.values()
    |> Enum.filter(&(is_integer(&1) and &1 > 0))
    |> Enum.reduce(nil, &min/2) # Note that atom > int
  end

  @spec can_allocate?(process, res | [res]) :: boolean when res: (:cpu | :ram | :dlk | :ulk)
  @doc """
  Checks if the `process` can allocate any of the specified `resources`
  """
  def can_allocate?(process, resources  \\ [:cpu, :ram, :dlk, :ulk]) do
    resources = List.wrap(resources)
    Enum.any?(can_allocate(process), &(&1 in resources))
  end

  # TODO: rename this
  @spec can_allocate(process) :: [:cpu | :ram | :dlk | :ulk]
  @doc """
  Returns a list with all resources that the `process` can allocate
  """
  def can_allocate(process = %Ecto.Changeset{}),
    do: can_allocate(apply_changes(process))
  def can_allocate(process = %__MODULE__{}) do
    objective_allows? = case process.objective do
      nil ->
        fn _ ->
          true
        end
      objective ->
        remaining = Resources.sub(objective, process.processed)
        fn resource ->
          still_to_be_processed_amount = Map.get(remaining, resource)

          is_integer(still_to_be_processed_amount)
          and still_to_be_processed_amount > 0
        end
    end

    process.process_data
    |> ProcessType.dynamic_resources()
    |> Enum.filter(fn resource ->
      # Note that this is `nil` unless a value is specified.
      # Also note that nil is greater than any integer :)
      limitations = Map.get(process.limitations, resource)
      allocated = Map.get(process.allocated, resource)

      objective_allows?.(resource) and limitations > allocated
    end)
  end

  @spec put_defaults(Changeset.t) :: Changeset.t
  defp put_defaults(changeset) do
    cs =
      get_change(changeset, :limitations)
      && changeset
      || put_embed(changeset, :limitations, %{})

    cs
    |> put_embed(:processed, %{})
    |> put_embed(:allocated, %{})
  end

  @spec server_to_process_map(Changeset.t) :: Changeset.t
  defp server_to_process_map(changeset) do
    id = get_field(changeset, :process_id)
    process_type = get_field(changeset, :process_type)

    params1 = %{
      server_id: get_field(changeset, :gateway_id),
      process_id: id,
      process_type: process_type
    }
    params2 = %{
      server_id: get_field(changeset, :target_server_id),
      process_id: id,
      process_type: process_type
    }

    # Should both records be identical, dedup will remove one of them
    records = Enum.dedup([params1, params2])

    put_assoc(changeset, :server_to_process_map, records)
  end

  @spec diff_in_seconds(DateTime.t, DateTime.t) :: non_neg_integer | nil
  docp """
  Returns the difference in seconds from `start` to `finish`

  This assumes that both the inputs are using UTC. This implementation might and
  should be replaced by a calendar library diff function
  """
  defp diff_in_seconds(%DateTime{}, nil),
    do: nil
  defp diff_in_seconds(start = %DateTime{}, finish = %DateTime{}),
    do: Timex.diff(start, finish, :seconds)

  @spec calculate_processed(process, non_neg_integer) :: Resources.t
  defp calculate_processed(process, delta_t) do
    cs = change(process)

    diff = cs |> get_field(:allocated) |> Resources.mul(delta_t)

    cs
    |> get_field(:processed)
    |> Resources.sum(diff)
    |> Resources.min(get_field(cs, :objective))
  end

  defmodule Query do
    alias Helix.Process.Model.Process
    alias Helix.Process.Model.Process.MapServerToProcess
    alias Helix.Process.Model.Process.State

    import Ecto.Query, only: [join: 5, where: 3]

    @spec from_server(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    @doc """
    Filter processes that are running on `server_id`
    """
    def from_server(query \\ Process, server_id) do
      where(query, [p], p.server_id == ^server_id)
    end

    @spec from_type_list(Ecto.Queryable.t, [String.t]) :: Ecto.Queryable.t
    def from_type_list(query \\ Process, type_list),
      do: where(query, [p], p.process_type in ^type_list)

    @spec from_state_list(Ecto.Queryable.t, [State.state]) :: Ecto.Queryable.t
    def from_state_list(query \\ Process, state_list),
      do: where(query, [p], p.state in ^state_list)

    @spec by_id(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_id(query \\ Process, process_id),
      do: where(query, [p], p.process_id == ^process_id)

    @spec by_gateway(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_gateway(query \\ Process, gateway_id),
      do: where(query, [p], p.gateway_id == ^gateway_id)

    @spec by_target(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_target(query \\ Process, target_server_id),
      do: where(query, [p], p.target_server_id == ^target_server_id)

    @spec by_file(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_file(query \\ Process, file_id),
      do: where(query, [p], p.file_id == ^file_id)

    @spec by_network(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_network(query \\ Process, network_id),
      do: where(query, [p], p.network_id == ^network_id)

    @spec by_type(Ecto.Queryable.t,String.t) :: Ecto.Queryable.t
    def by_type(query \\ Process, process_type),
      do: where(query, [p], p.process_type == ^process_type)

    @spec by_state(Ecto.Queryable.t, State.state) :: Ecto.Queryable.t
    def by_state(query \\ Process, state),
      do: where(query, [p], p.state == ^state)

    @spec related_to_server(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    @doc """
    Filter processes that are running on `server_id` or affect it
    """
    def related_to_server(query \\ Process, server_id) do
      query
      |> join(
        :inner,
        [p],
        m in MapServerToProcess,
        m.process_id == p.process_id)
      |> where([p, ..., m], m.server_id == ^server_id)
    end

    def related_to_server_and_of_types(query \\ Process, server_id, types) do
      types = List.wrap(types)

      query
      |> related_to_server(server_id)
      |> where([p, ..., m], m.process_type in ^types)
    end
  end
end
