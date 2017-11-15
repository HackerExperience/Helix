defmodule Helix.Server.Seed do

  alias Helix.Server.Component.Specs, as: ComponentSpecs

  alias Helix.Server.Repo

  def migrate do
    add_component_types()
    add_component_specs()
  end

  defp add_component_types do
    # TODO
    alias Helix.Hardware.Model.ComponentType
    Repo.transaction fn ->
      Enum.each(ComponentType.possible_types, fn type ->
        Repo.insert!(%ComponentType{component_type: type}, on_conflict: :nothing)
      end)
    end
  end

  defp add_component_specs do

    ComponentSpecs.generate_specs()
    |> Enum.each(fn {component_type, specs} ->
      Enum.each(specs, fn spec ->

        ComponentSpecs.create_changeset(spec.spec_id, component_type, spec)
        |> Repo.insert()

      end)
    end)

  end

end
