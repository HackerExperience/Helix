defmodule Helix.Hardware.Controller.ComponentSpec do

  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Repo

  @type find_params :: {:component_type, String.t}

  @spec create(ComponentSpec.spec) :: {:ok, ComponentSpec.t} | {:error, Ecto.Changeset.t}
  def create(spec_params) do
    spec_params
    |> ComponentSpec.create_from_spec()
    |> Repo.insert()
  end

  @spec fetch(String.t) :: ComponentSpec.t | nil
  def fetch(spec_id),
    do: Repo.get(ComponentSpec, spec_id)

  @spec find([find_params], meta :: []) :: [ComponentSpec.t]
  def find(params, _meta \\ []) do
    params
    |> Enum.reduce(ComponentSpec, &reduce_find_params/2)
    |> Repo.all()
  end

  @spec delete(ComponentSpec.t | String.t) :: no_return
  def delete(%ComponentSpec{spec_id: sid}),
    do: delete(sid)
  def delete(spec_id) do
    spec_id
    |> ComponentSpec.Query.by_id()
    |> Repo.delete_all()

    :ok
  end

  @spec reduce_find_params(find_params, Ecto.Queryable.t) :: Ecto.Queryable.t
  def reduce_find_params({:component_type, spec_type}, query),
    do: ComponentSpec.Query.by_component_type(query, spec_type)
end
