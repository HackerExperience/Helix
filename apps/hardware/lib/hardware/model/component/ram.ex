defmodule Helix.Hardware.Model.Component.RAM do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Hardware.Model.Component

  import Ecto.Changeset

  @type t :: %__MODULE__{
    ram_id: PK.t,
    ram_size: non_neg_integer,
    component: Component.t
  }

  @primary_key false
  schema "rams" do
    field :ram_id, PK,
      primary_key: true

    field :ram_size, :integer

    belongs_to :component, Component,
      foreign_key: :ram_id,
      references: :component_id,
      type: PK,
      define_field: false,
      on_replace: :delete
  end

  @spec create_changeset(%{any => any}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:ram_id])
    |> changeset(params)
  end

  @spec update_changeset(t | Ecto.Changeset.t, %{any => any}) :: Ecto.Changeset.t
  def update_changeset(struct, params),
    do: changeset(struct, params)

  @spec changeset(t | Ecto.Changeset.t, %{any => any}) :: Ecto.Changeset.t
  def changeset(struct, params) do
    struct
    |> cast(params, [:ram_size])
    |> validate()
  end

  @spec validate(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp validate(changeset) do
    changeset
    |> validate_required(:ram_size)
    |> validate_number(:ram_size, greater_than_or_equal_to: 0)
  end

  defmodule Query do

    alias Helix.Hardware.Model.Component.RAM

    import Ecto.Query, only: [where: 3]

    @spec from_component_ids([HELL.PK.t]) :: Ecto.Queryable.t
    @spec from_component_ids(Ecto.Queryable.t, [HELL.PK.t]) :: Ecto.Queryable.t
    def from_component_ids(query \\ RAM, component_ids) do
      where(query, [r], r.ram_id in ^component_ids)
    end
  end
end