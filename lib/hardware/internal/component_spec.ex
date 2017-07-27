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

  @spec fetch(ComponentSpec.t | ComponentSpec.id) ::
    ComponentSpec.t
    | nil
  def fetch(spec) do
    spec
    |> ComponentSpec.Query.by_spec()
    |> Repo.one
  end

  @spec delete(ComponentSpec.t | ComponentSpec.id) ::
    :ok
  def delete(spec) do
    spec
    |> ComponentSpec.Query.by_spec()
    |> Repo.delete_all()

    :ok
  end
end
