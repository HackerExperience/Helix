defmodule Helix.Hardware.Model.ComponentSpec do

  use Ecto.Schema

  alias Helix.Hardware.Model.ComponentType

  import Ecto.Changeset

  @type t :: %__MODULE__{
  }

  @type spec :: %{
    :spec_code => String.t,
    :spec_type => String.t,
    :name => String.t,
    optional(atom) => any
  }

  @type creation_params :: %{
    spec: spec
  }

  @callback validate_spec(map) :: Ecto.Changeset.t

  @valid_spec_types ComponentType.type_implementations() |> Map.keys() |> Enum.map(&String.upcase/1)
  @spec_type_implementation ComponentType.type_implementations() |> Enum.map(fn {k, v} -> {String.upcase(k), v} end) |> :maps.from_list()
  @spec_type_to_component_type ComponentType.type_implementations() |> Enum.map(fn {k, _} -> {String.upcase(k), k} end) |> :maps.from_list()

  @primary_key false
  schema "component_specs" do
    field :spec_id, :string,
      primary_key: true

    # FK to ComponentType
    field :component_type, :string
    field :spec, :map

    timestamps()
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> change()
    |> cast_and_validate_spec(params)
    |> validate_required([:component_type, :spec, :spec_id])
  end

  @spec create_from_spec(spec) :: Ecto.Changeset.t
  def create_from_spec(spec),
    do: create_changeset(%{spec: spec})

  @spec cast_and_validate_spec(Ecto.Changeset.t, %{spec: spec}) :: Ecto.Changeset.t
  defp cast_and_validate_spec(changeset, params) do
    spec = Map.get(params, :spec, %{})

    base_cs = prevalidate_spec(spec)
    impl_cs = validate_spec_by_type(spec)

    final_spec = Map.merge(apply_changes(base_cs), apply_changes(impl_cs))

    changes = %{
      component_type: @spec_type_to_component_type[final_spec.spec_type],
      spec_id: final_spec.spec_code,
      spec: final_spec
    }

    changeset
    |> change(changes)
    |> add_errors_if_spec_changeset_invalid(base_cs, impl_cs)
  end

  @spec prevalidate_spec(spec) :: Ecto.Changeset.t
  defp prevalidate_spec(params) do
    data = %{
      spec_code: nil,
      spec_type: nil,
      name: nil
    }
    types = %{
      spec_code: :string,
      spec_type: :string,
      name: :string
    }

    {data, types}
    |> cast(params, [:spec_code, :spec_type, :name])
    |> validate_required([:spec_code, :spec_type, :name])
    |> validate_format(:spec_code, ~r/^[A-Z0-9_]{4,64}$/)
    |> validate_inclusion(:spec_type, @valid_spec_types)
    |> validate_length(:name, min: 3, max: 64)
  end

  @spec validate_spec_by_type(map) :: Ecto.Changeset.t
  defp validate_spec_by_type(params) do
    implementation = Map.get(@spec_type_implementation, params[:spec_type])

    if implementation do
      implementation.validate_spec(params)
    else
      # Empty changeset, hack to ensure that the returned value is a valid
      # changeset
      change({%{}, %{}})
    end
  end

  @spec add_errors_if_spec_changeset_invalid(Ecto.Changeset.t, Ecto.Changeset.t, Ecto.Changeset.t) :: Ecto.Changeset.t
  defp add_errors_if_spec_changeset_invalid(changeset, %{valid?: true}, %{valid?: true}),
    do: changeset
  defp add_errors_if_spec_changeset_invalid(changeset, cs0, cs1),
    do: add_error(changeset, :spec, "is invalid", cs0.errors ++ cs1.errors)

  defmodule Query do

    alias Helix.Hardware.Model.ComponentSpec

    import Ecto.Query, only: [where: 3]

    @spec by_id(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_id(query \\ ComponentSpec, spec_id) do
      where(query, [s], s.spec_id == ^spec_id)
    end
  end
end
