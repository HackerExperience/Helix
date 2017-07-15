defmodule Helix.Hardware.Internal.ComponentSpec do

  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Repo

  @spec create(ComponentSpec.spec) ::
    {:ok, ComponentSpec.t}
    | {:error, Ecto.Changeset.t}
  def create(spec_params) do
    spec_params
    |> ComponentSpec.create_from_spec()
    |> Repo.insert()
  end

  @spec fetch(ComponentSpec.id) ::
    ComponentSpec.t
    | nil
  def fetch(spec_id),
    do: Repo.get(ComponentSpec, spec_id)

  @spec delete(ComponentSpec.t | ComponentSpec.id) ::
    :ok
  def delete(%ComponentSpec{spec_id: sid}),
    do: delete(sid)
  def delete(spec_id) do
    spec_id
    |> ComponentSpec.Query.by_id()
    |> Repo.delete_all()

    :ok
  end
end
