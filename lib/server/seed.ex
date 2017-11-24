defmodule Helix.Server.Seed do

  alias HELL.Utils
  alias Helix.Server.Component.Specable
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Server
  alias Helix.Server.Repo

  def migrate do
    add_component_types()
    add_component_specs()
    add_server_types()
  end

  defp add_component_types do
    Repo.transaction fn ->
      Enum.each(Component.get_types, fn type ->
        Repo.insert!(%Component.Type{type: type}, on_conflict: :nothing)
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

  defp add_server_types do
    Repo.transaction fn ->
      Enum.each(Server.Type.possible_types(), fn type ->
        Repo.insert!(%Server.Type{type: type}, on_conflict: :nothing)
      end)
    end
  end
end
