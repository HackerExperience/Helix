defmodule Helix.Hardware.Model.ComponentSpec do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Hardware.Model.ComponentType

  @type id :: String.t
  @type t :: %__MODULE__{}

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

  @valid_spec_types (
    ComponentType.possible_types()
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.upcase/1))

  @spec_type_implementation (
    ComponentType.type_implementations()
    |> Enum.map(fn {k, v} -> {String.upcase(to_string(k)), v} end)
    |> :maps.from_list())

  @spec_type_to_component_type (
    ComponentType.possible_types()
    |> Enum.map(fn k -> {String.upcase(to_string(k)), k} end)
    |> :maps.from_list())

  @primary_key false
  schema "component_specs" do
    field :spec_id, :string,
      primary_key: true

    # FK to ComponentType
    field :component_type, Constant
    field :spec, :map,
      # HACK: Yes, this is totally unnecessary, but the `spec` field after
      #   applying our changeset validation logic is returned with keys as atoms
      #   while when you fetch it from the database the keys will be strings
      #   so this will use a `returning` statement that will parse the return
      #   and it'll be get with keys as strings. Yes, this sucks, i might fix
      #   it in the future
      read_after_writes: true

    timestamps()
  end

  @doc false
  def valid_spec_types,
    do: @valid_spec_types

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> change()
    |> cast_and_validate_spec(params)
    |> validate_required([:component_type, :spec, :spec_id])
  end

  @spec create_from_spec(spec) ::
    Changeset.t
  def create_from_spec(spec),
    do: create_changeset(%{spec: spec})

  @spec cast_and_validate_spec(Changeset.t, %{spec: spec}) ::
    Changeset.t
  defp cast_and_validate_spec(changeset, params) do
    spec = Map.get(params, :spec, %{})

    base_cs = prevalidate_spec(spec)
    impl_cs = validate_spec_by_type(base_cs, spec)

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

  @spec prevalidate_spec(spec) ::
    Changeset.t
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
    |> validate_format(:spec_code, ~r/^[A-Z0-9_]{4,32}$/)
    |> validate_inclusion(:spec_type, @valid_spec_types)
    |> validate_length(:name, min: 3, max: 64)
  end

  @spec validate_spec_by_type(Changeset.t, map) ::
    Changeset.t
  defp validate_spec_by_type(base_changeset, params) do
    spec_type = get_change(base_changeset, :spec_type)
    implementation = Map.get(@spec_type_implementation, spec_type)

    if implementation do
      implementation.validate_spec(params)
    else
      # Empty changeset, hack to ensure that the returned value is a valid
      # changeset
      change({%{}, %{}})
    end
  end

  @spec add_errors_if_spec_changeset_invalid(Changeset.t, Changeset.t, Changeset.t) ::
    Changeset.t
  defp add_errors_if_spec_changeset_invalid(changeset, %{valid?: true}, %{valid?: true}),
    do: changeset
  defp add_errors_if_spec_changeset_invalid(changeset, cs0, cs1),
    do: add_error(changeset, :spec, "is invalid", cs0.errors ++ cs1.errors)

  defmodule Query do

    import Ecto.Query, only: [where: 3]

    alias Ecto.Queryable
    alias HELL.Constant
    alias Helix.Hardware.Model.ComponentSpec

    @spec by_spec(ComponentSpec.t | ComponentSpec.id) ::
      Queryable.t
    def by_spec(query \\ ComponentSpec, spec_or_spec_id)
    def by_spec(query, %ComponentSpec{spec_id: spec_id}),
      do: by_spec(query, spec_id)
    def by_spec(query, spec_id),
      do: where(query, [cs], cs.spec_id == ^spec_id)

    @spec by_component_type(Queryable.t, Constant.t) ::
      Queryable.t
    def by_component_type(query \\ ComponentSpec, component_type),
      do: where(query, [cs], cs.component_type == ^component_type)
  end
end
