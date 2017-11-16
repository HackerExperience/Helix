defmodule Helix.Test.Server.Component.Setup do

  alias Ecto.Changeset
  alias Helix.Server.Model.Component
  alias Helix.Server.Repo, as: ServerRepo

  alias Helix.Test.Server.Component.Helper, as: ComponentHelper

  @doc """
  See doc on `fake_component/1`
  """
  def component(opts \\ []) do
    {_, related = %{changeset: changeset}} = fake_component(opts)
    {:ok, inserted} = ServerRepo.insert(changeset)
    {inserted, related}
  end

  @doc """
  - spec_id: Set spec id. Defaults to randomly generated one
  - type: component type. Ignored if `spec_id` is passed

  Related: Component.Spec.t, Component.changeset
  """
  def fake_component(opts \\ []) do

    spec =
      if opts[:spec_id] do
        Component.Spec.fetch(opts[:spec_id])
      else
        opts = opts[:type] && [type: opts[:type]] || []
        ComponentHelper.random_spec(opts)
      end

    changeset = Component.create_from_spec(spec)

    component = Changeset.apply_changes(changeset)

    related =
      %{
        spec: spec,
        changeset: changeset
      }

    {component, related}
  end
end
