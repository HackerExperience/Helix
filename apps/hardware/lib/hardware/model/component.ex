defmodule Helix.Hardware.Model.Component do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Hardware.Model.Component.CPU
  alias Helix.Hardware.Model.Component.HDD
  alias Helix.Hardware.Model.Component.NIC
  alias Helix.Hardware.Model.Component.RAM
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.MotherboardSlot

  import Ecto.Changeset

  @type t :: %__MODULE__{
    component_id: PK.t,
    component_type: String.t,
    component_spec: ComponentSpec.t,
    spec_id: String.t,
    slot: MotherboardSlot.t,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{component_type: String.t, spec_id: String.t}

  @creation_fields ~w/component_type spec_id/a

  @primary_key false
  schema "components" do
    field :component_id, HELL.PK,
      primary_key: true

    field :component_type, :string

    belongs_to :component_spec, ComponentSpec,
      foreign_key: :spec_id,
      references: :spec_id,
      type: :string
    has_one :slot, MotherboardSlot,
      foreign_key: :link_component_id,
      references: :component_id

    # Specializations (included just to allow preparing them)
    has_one :cpu, CPU,
      foreign_key: :cpu_id,
      references: :component_id
    has_one :hdd, HDD,
      foreign_key: :hdd_id,
      references: :component_id
    has_one :nic, NIC,
      foreign_key: :nic_id,
      references: :component_id
    has_one :ram, RAM,
      foreign_key: :ram_id,
      references: :component_id

    timestamps()
  end

  @spec create_from_spec(ComponentSpec.t) :: Ecto.Changeset.t
  def create_from_spec(cs = %ComponentSpec{}) do
    params = %{component_type: cs.component_type, spec_id: cs.spec_id}

    params
    |> create_changeset()
    |> prepare_from_spec(cs.spec)
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:component_type, :spec_id])
    |> put_primary_key()
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    if get_field(changeset, :component_id) do
      changeset
    else
      pk = PK.generate([0x0003, 0x0001, 0x0000])

      cast(changeset, %{component_id: pk}, [:component_id])
    end
  end

  defp prepare_from_spec(changeset, spec) do
    component_id = get_field(changeset, :component_id)

    {assoc, component_specialization} = case spec do
      %{"spec_type" => "CPU"} ->
        cpu =
          spec
          |> Map.take(["clock", "cores"])
          |> Map.put("cpu_id", component_id)
          |> CPU.create_changeset()
        {:cpu, cpu}
      %{"spec_type" => "HDD"} ->
        hdd =
          spec
          |> Map.take(["size"])
          |> Map.put("hdd_id", component_id)
          |> HDD.create_changeset()
        {:hdd, hdd}
      %{"spec_type" => "NIC"} ->
        nic =
          spec
          |> Map.take(["downlink", "uplink"])
          |> Map.put("nic_id", component_id)
          |> NIC.create_changeset()
        {:nic, nic}
      %{"spec_type" => "RAM"} ->
        ram =
          spec
          |> Map.take(["size"])
          |> Map.put("ram_id", component_id)
          |> RAM.create_changeset()
        {:ram, ram}
      _ ->
        {nil, %{valid?: false, errors: []}}
    end

    if component_specialization.valid? do
      prepare_changes(changeset, fn changeset ->
        put_assoc(changeset, assoc, component_specialization)
      end)
    else
      add_error(changeset, :component_spec, "invalid spec", component_specialization.errors)
    end
  end

  defmodule Query do

    alias Helix.Hardware.Model.Component

    import Ecto.Query, only: [where: 3]

    def by_id(query \\ Component, component_id) do
      where(query, [c], c.component_id == ^component_id)
    end
  end
end