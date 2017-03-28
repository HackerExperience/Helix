defmodule Helix.Hardware.Controller.Component do

  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.ComponentType
  alias Helix.Hardware.Repo

  @type find_param ::
    {:id, [HELL.PK.t] | HELL.PK.t}
    | {:type, [String.t] | String.t}

  @spec create_from_spec(ComponentSpec.t) ::
    {:ok, Component.t}
    | {:error, Ecto.Changeset.t}
  def create_from_spec(spec = %ComponentSpec{}) do
    module = ComponentType.type_implementation(spec.component_type)

    changeset = module.create_from_spec(spec)

    case Repo.insert(changeset) do
      {:ok, %{component: c}} ->
        {:ok, c}
      e ->
        e
    end
  end

  @spec fetch(HELL.PK.t) :: Component.t | nil
  def fetch(component_id),
    do: Repo.get(Component, component_id)

  @spec find([find_param], meta :: []) :: [Component.t]
  def find(params, _meta \\ []) do
    params
    |> Enum.reduce(Component, &reduce_find_params/2)
    |> Repo.all()
  end

  @spec delete(HELL.PK.t) :: no_return
  def delete(component_id) do
    component_id
    |> Component.Query.by_id()
    |> Repo.delete_all()

    :ok
  end

  @spec reduce_find_params(find_param, Ecto.Queryable.t) :: Ecto.Queryable.t
  defp reduce_find_params({:id, several_ids}, query)
  when is_list(several_ids),
    do: Component.Query.from_id_list(query, several_ids)
  defp reduce_find_params({:id, id}, query),
    do: Component.Query.from_id_list(query, id)
  defp reduce_find_params({:type, several_types}, query)
  when is_list(several_types),
    do: Component.Query.from_type_list(query, several_types)
  defp reduce_find_params({:type, type}, query),
    do: Component.Query.by_type(query, type)
end
