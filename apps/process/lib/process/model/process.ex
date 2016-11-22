defmodule Helix.Process.Model.Process do

  use Ecto.Schema

  alias HELL.IPv6
  alias Helix.Process.Model.Process.Resources
  alias Helix.Process.Model.Process.Limitations
  alias Helix.Process.Model.Process.State
  alias Helix.Process.Model.Process.NaiveStruct
  alias Helix.Process.Model.Process.SoftwareType

  import Ecto.Changeset
  import Ecto.Query, only: [where: 3]

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

  @primary_key {:process_id, EctoNetwork.INET, autogenerate: false}

  schema "processes" do
    # The gateway that started the process
    field :gateway_id, :string
    field :target_server_id, :string
    field :file_id, :string

    # Data that is used by the specific implementation of the process side-effects
    field :software, NaiveStruct

    # Which state in the process FSM the process is currently on
    field :state, State, default: :standby
    # What is the process priority on the Table of Processes
    field :priority, :integer, default: 3

    embeds_one :objective, Resources
    embeds_one :processed, Resources
    embeds_one :allocated, Resources
    embeds_one :limitations, Limitations

    field :creation_time, Ecto.DateTime, autogenerate: true
    field :updated_time, Ecto.DateTime, autogenerate: true
    field :estimated_time, Ecto.DateTime, virtual: true
  end

  @creation_fields ~w/gateway_id file_id software target_server_id/a
  @update_fields ~w/state priority creation_time updated_time estimated_time/a

  @spec create_changeset(%{
    gateway_id: String.t,
    target_server_id: String.t,
    file_id: String.t,
    software: SoftwareType.t,
    objective: %{}}) :: Ecto.Changeset.t
  def create_changeset(params) do
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
  end

  @spec update_changeset(
    t | Ecto.Changeset.t,
    %{
      state: State.states,
      priority: 0..5,
      creation_time: DateTime.t,
      updated_time: DateTime.t,
      estimated_time: DateTime.t,
      objective: %{},
      processed: %{},
      allocated: %{}}) :: Ecto.Changeset.t
  def update_changeset(process, params) do
    process
    |> cast(params, @update_fields)
    |> validate_inclusion(:priority, 0..5)
    |> cast_embed(:objective)
    |> cast_embed(:processed)
    |> cast_embed(:allocated)
  end

  @spec calculate_work(t | Ecto.Changeset.t, DateTime.t) :: Ecto.Changeset.t
  def calculate_work(process, time_now) do
    case process do
      %Ecto.Changeset{} ->
        new_data = process.data |> calculate_work(time_now)

        merge(process, new_data)

      %__MODULE__{state: :running} ->
        diff = diff_in_seconds(process.updated_time, time_now)

        changes = %{
          updated_time: time_now,
          processed: calculate_processed(process, diff),
        }

        update_changeset(process, changes)

      %__MODULE__{} ->
        update_changeset(process, %{updated_time: time_now})
    end
  end

  @spec estimate_conclusion(elem) :: elem when elem: t | Ecto.Changeset.t
  def estimate_conclusion(process) do
    struct = case process do
      %__MODULE__{} ->
        process
      %Ecto.Changeset{} ->
        apply_changes(process)
    end

    conclusion =
      struct.objective
      |> Resources.sub(struct.processed)
      |> Resources.div(struct.allocated)
      |> Resources.to_list()
      |> Enum.filter_map(fn {_, x} -> x != 0 end, &elem(&1, 1))
      |> Enum.reduce(0, &max/2)
      |> case do
        0 ->
          # Exceptional case when all resources are "0" (ie: nothing to do)
          nil
        nil ->
          nil
        x ->
          struct.updated_time
          |> ecto_conversion_workaround()
          |> Timex.shift(seconds: x)
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
    |> Enum.filter_map(fn {_, x} -> is_integer(x) and x > 0 end, &elem(&1, 1))
    |> Enum.reduce(nil, &min/2)
  end

  @spec can_allocate?(t, atom | [atom]) :: boolean
  def can_allocate?(process, resource \\ [:cpu, :ram, :dlk, :ulk]) do
    remaining = Resources.sub(process.objective, process.processed)

    # TODO: Check if the allocation strategy allows dynamic allocation

    resource
    |> List.wrap()
    |> Enum.any?(fn resource ->
      v = Map.get(remaining, resource)

      is_integer(v)
      and v > 0
      and Map.get(process.limitations, resource) > Map.get(process.allocated, resource)
    end)
  end

  @spec from_list(Ecto.Queryable.t, [id]) :: Ecto.Queryable.t
  def from_list(query, process_ids) do
    query
    |> where([p], p.process_id in ^process_ids)
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    ip = IPv6.generate([0x0005, 0x0000, 0x0000])

    changeset
    |> cast(%{process_id: ip}, [:process_id])
  end

  @spec put_defaults(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_defaults(changeset) do
    put_default(changeset, [:objective, :processed, :allocated, :limitations])
  end

  @spec put_default(Ecto.Changeset.t, [atom]) :: Ecto.Changeset.t
  defp put_default(changeset, [:objective| t]) do
    if get_change(changeset, :objective) do
      put_default(changeset, t)
    else
      changeset
      |> put_embed(:objective, %Resources{})
      |> put_default(t)
    end
  end

  defp put_default(changeset, [:processed| t]) do
    changeset
    |> put_embed(:processed, %Resources{})
    |> put_default(t)
  end

  defp put_default(changeset, [:allocated| t]) do
    changeset
    |> put_embed(:allocated, %Resources{})
    |> put_default(t)
  end

  defp put_default(changeset, [:limitations| t]) do
    if get_change(changeset, :limitations) do
      put_default(changeset, t)
    else
      changeset
      |> put_embed(:limitations, %Limitations{})
      |> put_default(t)
    end
  end

  defp put_default(changeset, []) do
    changeset
  end

  @spec diff_in_seconds(DateTime.t | Ecto.DateTime.t, DateTime.t) :: non_neg_integer | nil
  @docp """
  Returns the difference in seconds from `start` to `finish`

  This assumes that both the inputs are using UTC. This implementation might and
  should be replaced by a calendar library diff function
  """
  defp diff_in_seconds(%Ecto.DateTime{}, nil),
    do: nil
  defp diff_in_seconds(start = %Ecto.DateTime{}, finish = %DateTime{}) do
    start
    |> ecto_conversion_workaround()
    |> diff_in_seconds(finish)
  end

  defp diff_in_seconds(start = %DateTime{}, finish = %DateTime{}) do
    Timex.diff(start, finish, :seconds)
  end

  @spec ecto_conversion_workaround(Ecto.DateTime.t) :: DateTime.t
  @docp """
  Right now Ecto.DateTime doesn't have an easy and clear way to be converted to
  calendar types, albeit this is going to be implemented in the near future.

  Meanwhile, this workaround will convert it to the DateTime type by passing it
  through a pipeline of transformations
  """
  defp ecto_conversion_workaround(datetime) do
    datetime
    |> Ecto.DateTime.to_erl()
    |> :calendar.datetime_to_gregorian_seconds()
    |> Kernel.-(62_167_219_200) # EPOCH in seconds
    |> DateTime.from_unix!()
  end

  @spec calculate_processed(t, non_neg_integer) :: Resources.t
  defp calculate_processed(process, diff) do
    process.software
    |> SoftwareType.allocation_handler()
    |> apply(:calculate_processed, [process, diff])
  end
end