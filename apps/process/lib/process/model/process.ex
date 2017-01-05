defmodule Helix.Process.Model.Process do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Process.Model.Process.Resources
  alias Helix.Process.Model.Process.Limitations
  alias Helix.Process.Model.Process.State
  alias Helix.Process.Model.Process.NaiveStruct
  alias Helix.Process.Model.Process.SoftwareType

  import Ecto.Changeset
  import Ecto.Query, only: [where: 3]
  import HELL.MacroHelpers

  @type t :: %__MODULE__{
    process_id: id,
    gateway_id: String.t,
    software: SoftwareType.t,
    state: State.states,
    limitations: Limitations.t,
    objective: Resources.t,
    processed: Resources.t,
    allocated: Resources.t,
    priority: 0..5
  }

  @opaque id :: String.t

  @primary_key false
  schema "processes" do
    field :process_id, HELL.PK,
      primary_key: true

    # The gateway that started the process
    field :gateway_id, EctoNetwork.INET
    # The server where the target object of this process action is
    field :target_server_id, EctoNetwork.INET
    # Which file (if any) contains the "executable" of this process
    field :file_id, EctoNetwork.INET

    # Data that is used by the specific implementation of the process
    # side-effects
    field :software, NaiveStruct

    # Which state in the process FSM the process is currently on
    field :state, State, default: :standby
    # What is the process priority on the Table of Processes (only affects
    # dynamic allocation)
    field :priority, :integer, default: 3

    embeds_one :objective, Resources, on_replace: :delete
    embeds_one :processed, Resources, on_replace: :delete
    embeds_one :allocated, Resources, on_replace: :delete
    embeds_one :limitations, Limitations, on_replace: :delete

    # The minimum amount of resources this process requires (aka the static
    # amount of resources this process uses)
    field :minimum, :map, default: %{}, virtual: true

    field :creation_time, :utc_datetime
    field :updated_time, :utc_datetime
    field :estimated_time, :utc_datetime, virtual: true
  end

  @creation_fields ~w/gateway_id file_id software target_server_id/a
  @update_fields ~w/state priority updated_time estimated_time minimum/a

  @spec create_changeset(%{
    :gateway_id => String.t,
    :target_server_id => String.t,
    :software => SoftwareType.t,
    optional(:file_id) => String.t,
    optional(:objective) => %{}}) :: Ecto.Changeset.t
  def create_changeset(params) do
    now = DateTime.utc_now()
    default_datetime = %{creation_time: now, updated_time: now}

    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> cast_embed(:objective)
    |> validate_required([:gateway_id, :target_server_id, :software])
    |> validate_change(:software, fn :software, value ->
      # Only accepts as input structs that implement protocol SoftwareType to
      # ensure that they will be properly processed
      if SoftwareType.impl_for(value),
        do: [],
        else: [software: "invalid value"]
    end)
    |> put_primary_key()
    |> put_defaults()
    |> cast(default_datetime, [:creation_time, :updated_time])
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
    |> validate_inclusion(:priority, 0..5)
    |> cast_embed(:objective)
    |> cast_embed(:processed)
    |> cast_embed(:allocated)
    |> cast_embed(:limitations)
  end

  @spec complete?(t) :: boolean
  def complete?(p = %Ecto.Changeset{}),
    do: complete?(apply_changes(p))
  def complete?(%__MODULE__{state: :complete}),
    do: true
  def complete?(%__MODULE__{
    objective: %{cpu: c, ram: r, dlk: d, ulk: u},
    processed: %{cpu: c, ram: r, dlk: d, ulk: u}
  }),
    do: true
  def complete?(%__MODULE__{}),
    do: false

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
      |> Map.from_struct() # HACK: ecto cast doesn't accept structs

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

    update_changeset(process, %{allocated: allocated})
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

  @spec can_allocate?(t | Ecto.Changeset.t, atom | [atom]) :: boolean
  def can_allocate?(process, resource \\ [:cpu, :ram, :dlk, :ulk])

  def can_allocate?(process = %Ecto.Changeset{}, resources),
    do: can_allocate?(apply_changes(process), resources)
  def can_allocate?(%__MODULE__{objective: nil}, _),
    do: true
  def can_allocate?(process = %__MODULE__{}, resource) do
    remaining = Resources.sub(process.objective, process.processed)

    # TODO: Check if the allocation strategy allows dynamic allocation

    resource
    |> List.wrap()
    |> Enum.any?(fn resource ->
      r = Map.get(remaining, resource)
      l = Map.get(process.limitations, resource)
      a = Map.get(process.allocated, resource)

      is_integer(r) and r > 0 and l > a
    end)
  end

  @spec from_list(Ecto.Queryable.t, [id]) :: Ecto.Queryable.t
  def from_list(query, process_ids) do
    where(query, [p], p.process_id in ^process_ids)
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    pk = PK.generate([0x0005, 0x0000, 0x0000])

    cast(changeset, %{process_id: pk}, [:process_id])
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
end