defmodule Helix.Test.Server.Component.Helper do

  alias Helix.Server.Componentable
  alias Helix.Server.Model.Component

  @doc """
  - type: Spec type. Defaults to a random one from [:cpu, :hdd, :ram, :nic]
  """
  def random_spec(opts \\ []) do
    type = Keyword.get(opts, :type, Enum.random(possible_types()))

    spec_id =
      type
      |> Atom.to_string()
      |> String.upcase()
      |> Kernel.<>("_001")
      |> String.to_atom()

    Component.Spec.fetch(spec_id)
  end

  defp possible_types,
    do: Componentable.get_types()

  def id,
    do: Component.ID.generate(%{}, {:component, :cpu})
end
