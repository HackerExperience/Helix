defmodule Helix.Process.Model.Process do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Process.Model.Process.Limitations
  alias Helix.Process.Model.Process.MapServerToProcess
  alias Helix.Process.Model.Process.NaiveStruct
  alias Helix.Process.Model.Process.Resources
  alias Helix.Process.Model.Process.SoftwareType
  alias Helix.Process.Model.Process.State

  import Ecto.Changeset
  import HELL.MacroHelpers

  @type t :: %__MODULE__{
    process_id: id,
    gateway_id: PK.t,
    target_server_id: PK.t,
    file_id: PK.t | nil,
    network_id: PK.t | nil,
    software: SoftwareType.t,
    software_type: String.t,
    state: State.state,
    limitations: Limitations.t,
    objective: Resources.t,
    processed: Resources.t,
    allocated: Resources.t,
    priority: 0..5,
    minimum: %{},
    creation_time: DateTime.t,
    updated_time: DateTime.t,
    estimated_time: DateTime.t
  }

  @opaque id :: PK.t

  @primary_key false
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
    field :software, NaiveStruct

    # The type of software that defines the process behaviour.
    # This field might sound redundant when `:software` is a struct that might
    # allow us to infer the type of software, but this field is included to
    # allow filtering by software_type (and even blocking more than one process
    # of certain software_type from running on a server)
    field :software_type, :string

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

  @creation_fields ~w/software software_type gateway_id target_server_id file_id network_id/a
  @update_fields ~w/state priority updated_time estimated_time minimum/a

  @spec create_changeset(%{
    :gateway_id => PK.t,
    :target_server_id => PK.t,
    :software => SoftwareType.t,
    optional(:file_id) => PK.t,
    optional(:network_id) => PK.t,
    optional(:objective) => %{}}) :: Ecto.Changeset.t
  def create_changeset(params) do
    now = DateTime.utc_now()
    params =
      params
      |> Map.put(:creation_time, now)
      |> Map.put(:updated_time, now)

    %__MODULE__{}
    |> cast(params, [:creation_time| @creation_fields])
    |> validate_change(:software, fn :software, value ->
      # Only accepts as input structs that implement protocol SoftwareType to
      # ensure that they will be properly processed
      if SoftwareType.impl_for(value),
        do: [],
        else: [software: "invalid value"]
    end)
    |> put_primary_key()
    |> put_defaults()
    |> changeset(params)
    |> server_to_process_map()
  end

  @spec update_changeset(
    t | Ecto.Changeset.t,
    %{
      optional(:state) => State.states,
      optional(:priority) => 0..5,
      optional(:creation_time) => DateTime.t,
      optional(:updated_time) => DateTime.t,
      optional(:estimated_time) => DateTime.t,
      optional(:limitations) => %{},
      optional(:objective) => %{},
      optional(:processed) => %{},
      optional(:allocated) => %{},
      optional(:minimum) => %{}}) :: Ecto.Changeset.t
  def update_changeset(process, params) do
    process
    |> cast(params, @update_fields)
    |> cast_embed(:processed)
    |> cast_embed(:allocated)
    |> cast_embed(:limitations)
    |> changeset(params)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:updated_time])
    |> cast_embed(:objective)
    |> validate_required([:gateway_id, :target_server_id, :software, :software_type])
    |> validate_inclusion(:priority, 0..5)
  end

  @spec complete?(t) :: boolean
  def complete?(p = %Ecto.Changeset{}),
    do: complete?(apply_changes(p))
  def complete?(%__MODULE__{state: s, objective: o, processed: p}),
    do: s == :complete or o == p

  @spec handle_complete(t) :: t | nil
  def handle_complete(p) do
    # TODO: rename this to something that sounds like a real model function and
    #   not some garbage workaround
    p
  end

  @spec allocate_minimum(t | Ecto.Changeset.t) :: Ecto.Changeset.t
  def allocate_minimum(process) do
    process = change(process)
    minimum =
      process
      |> get_field(:minimum)
      |> Map.get(get_field(process, :state), %{})

    # FIXME: HACK
    allocate = Map.merge(%{cpu: 0, ram: 0, dlk: 0, ulk: 0}, minimum)

    put_embed(process, :allocated, allocate)
  end

  @spec allocate(t | Ecto.Changeset.t, Resources.t) :: Ecto.Changeset.t
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

  @spec allocation_shares(t | Ecto.Changeset.t) :: non_neg_integer
  def allocation_shares(process) do
    case process do
      %__MODULE__{state: s, priority: p} when s in [:standby, :running] ->
        can_allocate?(process) && p || 0
      %__MODULE__{} ->
        0
      %Ecto.Changeset{} ->
        process
        |> apply_changes()
        |> allocation_shares()
    end
  end

  @spec pause(t | Ecto.Changeset.t) :: Ecto.Changeset.t
  def pause(p = %__MODULE__{state: :paused}),
    do: change(p)
  def pause(p) do
    p
    |> calculate_work(DateTime.utc_now())
    |> update_changeset(%{state: :paused, estimated_time: nil})
    |> allocate_minimum()
  end

  @spec resume(t | Ecto.Changeset.t) :: Ecto.Changeset.t
  def resume(p) do
    state = p |> change() |> get_field(:state)

    if :paused === state do
      # FIXME: state can be "standby" on some cases
      p
      |> update_changeset(%{state: :running, updated_time: DateTime.utc_now()})
      |> allocate_minimum()
      |> estimate_conclusion()
    else
      change(p)
    end
  end

  @spec calculate_work(t | Ecto.Changeset.t, DateTime.t) :: Ecto.Changeset.t
  def calculate_work(process, time_now) do
    cs = change(process)

    if :running === get_field(cs, :state) do
      diff = cs |> get_field(:updated_time) |> diff_in_seconds(time_now)

      process
      |> update_changeset(%{updated_time: time_now})
      |> put_embed(:processed, calculate_processed(process, diff))
    else
      process
    end
  end

  # REVIEW: FIXME: Maybe return as a changeset because life is a disaster
  @spec estimate_conclusion(elem) :: elem when elem: t | Ecto.Changeset.t
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

  @spec seconds_to_change(t) :: non_neg_integer | nil
  @doc """
  How many seconds until the `process` change state or frees some resource from
  completing part of it's objective
  """
  def seconds_to_change(process) do
    process.objective
    |> Resources.sub(process.processed)
    |> Resources.div(process.allocated)
    |> Resources.to_list()
    |> Keyword.values()
    |> Enum.filter(&(is_integer(&1) and &1 > 0))
    |> Enum.reduce(nil, &min/2)
  end

  @spec can_allocate?(t | Ecto.Changeset.t, res | [res]) :: boolean when res: (:cpu | :ram | :dlk | :ulk)
  def can_allocate?(processes, resources  \\ [:cpu, :ram, :dlk, :ulk]) do
    r = List.wrap(resources)
    Enum.any?(can_allocate(processes), &(&1 in r))
  end

  @spec can_allocate(t | Ecto.Changeset.t) :: [:cpu | :ram | :dlk | :ulk]
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
          r = Map.get(remaining, resource)
          is_integer(r) and r > 0
        end
    end

    process.software
    |> SoftwareType.dynamic_resources()
    |> Enum.filter(fn resource ->
      l = Map.get(process.limitations, resource)
      a = Map.get(process.allocated, resource)

      objective_allows?.(resource) and l > a
    end)
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    put_change(changeset, :process_id, PK.generate([0x0005, 0x0000, 0x0000]))
  end

  @spec put_defaults(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_defaults(changeset) do
    cs =
      get_change(changeset, :limitations)
      && changeset
      || put_embed(changeset, :limitations, %{})

    cs
    |> put_embed(:processed, %{})
    |> put_embed(:allocated, %{})
  end

  defp server_to_process_map(changeset) do
    gateway_id = get_field(changeset, :gateway_id)
    target_server_id = get_field(changeset, :target_server_id)
    id = get_field(changeset, :process_id)
    software_type = get_field(changeset, :software_type)

    p1 = %{server_id: gateway_id, process_id: id, software_type: software_type}

    records = if gateway_id == target_server_id do
      [MapServerToProcess.create_changeset(p1)]
    else
      p2 = %{p1| server_id: target_server_id}
      [
        MapServerToProcess.create_changeset(p1),
        MapServerToProcess.create_changeset(p2)
      ]
    end

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

  @spec calculate_processed(
    t | Ecto.Changeset.t,
    non_neg_integer) :: Resources.t
  defp calculate_processed(process, delta_t) do
    cs = change(process)

    diff = cs |> get_field(:allocated) |> Resources.mul(delta_t)

    cs
    |> get_field(:processed)
    |> Resources.sum(diff)
    |> Resources.min(get_field(cs, :objective))
  end

  defmodule Query do
    import Ecto.Query, only: [where: 3]

    @spec from_server(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    @doc """
    Filter processes that are running on `server_id`
    """
    def from_server(query, server_id) do
      where(query, [p], p.server_id == ^server_id)
    end

    @spec related_to_server(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    @doc """
    Filter processes that are running on `server_id` or affect it
    """
    def related_to_server(query, server_id) do
      where(
        query,
        [p],
        p.server_id == ^server_id or p.target_server_id == ^server_id)
    end
  end
end