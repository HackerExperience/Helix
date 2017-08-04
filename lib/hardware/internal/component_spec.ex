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
  def fetch(spec),
    do: Repo.get(ComponentSpec, spec)

  @spec delete(ComponentSpec.t) ::
    :ok
  def delete(spec) do
    Repo.delete(spec)

    :ok
  end
end
