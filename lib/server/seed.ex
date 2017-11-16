defmodule Helix.Server.Seed do

  alias HELL.Utils
  alias Helix.Server.Component.Specable
  alias Helix.Server.Model.Component
  alias Helix.Server.Repo

  def migrate do
    add_component_types()
    add_component_specs()
  end

  defp add_component_types do
    # TODO ComponentType
    alias Helix.Hardware.Model.ComponentType
    Repo.transaction fn ->
      Enum.each(ComponentType.possible_types, fn type ->
        Repo.insert!(%ComponentType{component_type: type}, on_conflict: :nothing)
      end)
    end
  end

  defp add_component_specs do

    Specable.generate_specs()
    |> Enum.each(fn {component_type, specs} ->
      Enum.each(specs, fn spec ->
        spec.spec_id
        |> Utils.downcase_atom()
        |> Component.Spec.create_changeset(component_type, spec)
        |> Repo.insert(on_conflict: :nothing)
      end)
    end)
  end
end
